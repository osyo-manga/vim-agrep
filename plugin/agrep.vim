scriptencoding utf-8
if exists('g:loaded_agrep')
  finish
endif
let g:loaded_agrep = 1

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* Agrep call agrep#start(<q-args>)
command! AgrepStop call agrep#latest_handle().stop()

command! -nargs=* AgrepResume call agrep#open_resume(<q-args>)

let &cpo = s:save_cpo
unlet s:save_cpo
