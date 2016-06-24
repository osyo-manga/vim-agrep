scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


let s:V = vital#agrep#of()
call vital#of("vital").unload()
let s:V = vital#of("vital")

let s:B = s:V.import("Coaster.Buffer")
let s:T = s:V.import("Branc.Timer")
let s:J = s:V.import("Branc.Job")


function! s:error(msg)
	echohl ErrorMsg
	echom "Error agrep.vim : " . a:msg
	echohl NONE
endfunction


let s:anime = { "count" : 0 }
function! s:anime.update(outputter, ...)
	let self.count += 1
	let icon = ["-", "\\", "|", "/"]
	let anime =  icon[self.count % len(icon)] . " Searching" . repeat(".", self.count % 5)
	call a:outputter(anime)
endfunction



function! s:set_qfline(lnum, item)
	let qflist = getqflist()
	if len(qflist) <= a:lnum
		call add(qflist, a:item)
	else
		let qflist[a:lnum] = a:item
	endif
	call setqflist(qflist)
endfunction


let s:handle = {}
function! s:handle.start(cmd) abort
	call self.stop()
	
	let c = (&shell =~ 'command.com$' || &shell =~ 'cmd.exe$' || &shell =~ 'cmd$') ? "/c" : "-c"

	let self.job = s:J.new({
\		"buffer_" : []
\	}).start([&shell, c, a:cmd])

	function! self.job._callback(channel, msg)
		let self.buffer_ += [a:msg]
	endfunction

	let self.job._close_cb = function(self._exit, [], self)

	let self.update_timer = s:T.start(1000, self._update, { "repeat" : -1 })

	let Outputter = function(self.output.setline, [1])
	let self.anime_timer = s:T.start(50, function(s:anime.update, [Outputter]), { "repeat" : -1 })

" 	cexpr []
" 	copen

	call self.output.clear()
	if !self.output.is_opened_in_current_tabpage()
		call self.output.open(self.config.open_cmd)
		execute "normal! \<C-w>p"
	endif
endfunction


function! s:handle.stop()
	if has_key(self, "job")
		call self.job.stop()
	endif
endfunction


function! s:handle._exit(...)
" 	call s:set_qfline(0, { "text" : "Finished" })
	call self.anime_timer.stop()
	call self.update_timer.stop()
	call self.output.setline(1, "Finished.")
	call self._update()
endfunction


function! s:handle.init()
	let self.count = 0
	let self.output = s:B.new_temp()
	call self.output.set_variable("&filetype", "agrep")
endfunction


function! s:handle._update(...)
	let buffer = self.job.buffer_
	if empty(buffer)
		return
	endif
	let lnum = self.output.line_length() + 1
	call self.output.setline(lnum, buffer)
endfunction


function! s:new(...)
	let config = get(a:, 1, { "open_cmd" : "split" })
	let handle = deepcopy(s:handle)
	let handle.config = config
	call handle.init()
	return handle
endfunction


" function! s:start(cmd, config)
" 	let handle = s:new(a:config)
" 	call handle.start(a:cmd)
" 	return handle
" endfunction



let s:default_config = {
\	"command" : "grep",
\	"option"  : "",
\	"open_cmd" : "split"
\}
let g:agrep#config = get(g:, "agrep#config", {})


function! agrep#get_config(...)
	return extend(extend(deepcopy(s:default_config), g:agrep#config), get(a:, 1, {}))
endfunction


unlet! s:latest_handle
function! agrep#start(args, ...)
	let config = agrep#get_config()
	if !executable(config.command)
		return s:error(printf("Not found '%s' command.", config.command))
	endif
	let cmd = config.command . " " . config.option . " " . a:args

	if exists("s:latest_handle")
		let handle = s:latest_handle
	else
		let handle = s:new(config)
	endif
	call handle.start(cmd)

" 	call handle.output.set_variable("agrep_handle", handle)

	let s:latest_handle = handle
endfunction


function! agrep#latest_handle()
	return get(s:, "latest_handle", {})
endfunction


function! agrep#open_resume(...)
	let handle = agrep#latest_handle()
	if empty(handle)
		return s:error("Not found handle.")
	endif
	let open_cmd = get(a:, 1, "")
	if empty(open_cmd)
		let open_cmd = agrep#get_config().open_cmd
	endif
	call agrep#latest_handle().output.open(open_cmd)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
