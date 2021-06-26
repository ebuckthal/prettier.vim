" in plugin/whid.vim
if exists('g:loaded_prettier_vim') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

" command to run our plugin
lua require('prettier');

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_prettier_vim = 1

