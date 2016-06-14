scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


" let s:B = vital#of("vital").import("Coaster.Buffer")

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
	
	let c = (&shell == "command.com" || &shell == "cmd.exe" || &shell == "cmd") ? "/c" : "-c"
	let self.job_id = job_start([&shell, c, a:cmd], {
\		"out_cb" : self._output,
\		"close_cb" : self._exit,
\	})

	let self.update_timer_id = timer_start(1000, self._update, { "repeat" : -1 })
	let self.draw_timer_id = timer_start(50, self._draw, { "repeat" : -1 })

	cexpr []
	copen
" 	call self.output.open(self.config.open_cmd)
" 	set filetype=agrep
	execute "normal! \<C-w>p"
endfunction


function! s:handle.stop()
	if has_key(self, "job_id")
		call job_stop(self.job_id)
	endif
endfunction


function! s:handle._output(channel, msg)
	let self.buffer += [a:msg]
endfunction


function! s:handle._update(...)
	try
		if empty(self.buffer)
			return
		endif

		cadde self.buffe
" 		call self.output.setline(self.output.line_length() + 1, self.buffer)
		let self.buffer = []
	catch
		call s:error("Error agrep.vim : " . v:exception . " " . v:throwpoint)
		call self.stop()
	endtry
endfunction


function! s:handle._draw(...)
	try
		if has_key(self, "job_id") && job_status(self.job_id) == "dead"
			return
		endif

		let self.count += 1
		let icon = ["-", "\\", "|", "/"]
		let anime =  icon[self.count % len(icon)] . " Searching" . repeat(".", self.count % 5)
		
		echo anime
" 		call self.output.setline(1, anime)
	catch
		call s:error("Error agrep.vim : " . v:exception . " " . v:throwpoint)
		call self.stop()
	endtry
endfunction


function! s:handle._init()
	let self.count = 0
" 	let self.output = s:B.new_temp()
	let self.buffer = []
endfunction


function! s:handle._exit(...)
	call self._update()

" 	call s:set_qfline(0, { "text" : "Finished" })
" 	call self.output.setline(1, "Finished.")

	call feedkeys(printf(":call timer_stop(%d)\<CR>", self.update_timer_id), "n")
	unlet self.update_timer_id

	call feedkeys(printf(":call timer_stop(%d)\<CR>", self.draw_timer_id), "n")
	unlet self.draw_timer_id
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


function! agrep#aget_config(...)
	return extend(extend(deepcopy(s:default_config), g:agrep#config), get(a:, 1, {}))
endfunction


function! agrep#start(args, ...)
	let config = agrep#aget_config()
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
