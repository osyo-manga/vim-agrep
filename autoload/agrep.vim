scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


" call vital#of("vital").unload()
" let s:v = vital#of("vital")
let s:V = vital#agrep#of()

let s:B = s:V.import("Coaster.Buffer")
let s:T = s:V.import("Branc.Timer")
" let s:T = vital#of("vital").import("Branc.Timer")

function! s:error(msg)
	echohl ErrorMsg
	echom "Error agrep.vim : " . a:msg
	echohl NONE
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
	let self.job_id = job_start([&shell, c, a:cmd], {
\		"out_cb" : self._output,
\		"err_cb" : self._output,
\		"close_cb" : self._exit,
\	})

	let update = s:T.new({
\		"handle_" : self
\	}).start(1000, { "repeat" : -1 })

	function! update._callback(...)
		let buffer = self.handle_.buffer
		if empty(buffer)
			return
		endif
		let lnum = self.handle_.output.line_length() + 1
		call self.handle_.output.setline(lnum, buffer)

		if job_status(self.handle_.job_id) == "dead"
			return self.stop()
		endif
	endfunction

	let anime = s:T.new({
\		"count_"  : 0,
\		"job_"    : self.job_id,
\		"output_" : self.output
\	}).start(50, { "repeat"  : -1})

	function! anime._callback(...)
		if job_status(self.job_) == "dead"
			return self.stop()
		endif
		let self.count_ += 1
		let icon = ["-", "\\", "|", "/"]
		let anime =  icon[self.count_ % len(icon)] . " Searching" . repeat(".", self.count_ % 5)
		call self.output_.setline(1, anime)
	endfunction

" 	cexpr []
" 	copen

	call self.output.open(self.config.open_cmd)

	set filetype=agrep
	execute "normal! \<C-w>p"
endfunction


function! s:handle.stop()
	if has_key(self, "job_id")
		call job_stop(self.job_id)
		unlet self.job_id
	endif
endfunction


function! s:handle._output(channel, msg)
	let self.buffer += [a:msg]
endfunction


function! s:handle._init()
	let self.count = 0
	let self.output = s:B.new_temp()
	let self.buffer = []
endfunction


function! s:handle._exit(...)
" 	call s:set_qfline(0, { "text" : "Finished" })
	call self.output.setline(1, "Finished.")

	if has_key(self, "update_buffer_timer_id")
		call timer_stop(self.update_buffer_timer_id)
		unlet self.update_buffer_timer_id
	endif

	if has_key(self, "update_anime_timer_id")
		call timer_stop(self.update_anime_timer_id)
		unlet self.update_anime_timer_id
	endif
endfunction


function! s:new(...)
	let config = get(a:, 1, { "open_cmd" : "split" })
	let handle = deepcopy(s:handle)
	let handle.config = config
	call handle._init()
	return handle
endfunction


function! s:start(cmd, config)
	let handle = s:new(a:config)
	call handle.start(a:cmd)
	return handle
endfunction



let s:default_config = {
\	"command" : "grep",
\	"option"  : "",
\	"open_cmd" : "split"
\}
let g:agrep#config = get(g:, "agrep#config", {})


function! agrep#get_config(...)
	return extend(extend(deepcopy(s:default_config), g:agrep#config), get(a:, 1, {}))
endfunction


function! agrep#start(args, ...)
	let config = agrep#get_config()
	if !executable(config.command)
		return s:error(printf("Not found '%s' command.", config.command))
	endif
	let cmd = config.command . " " . config.option . " " . a:args
	let handle = s:start(cmd, config)
" 	call handle.output.set_variable("agrep_handle", handle)
	let s:latest_handle = handle
endfunction

function! agrep#latest_handle()
	return get(s:, "latest_handle", {})
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
