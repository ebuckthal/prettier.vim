if !exists('g:prettier_cmd')
  let g:prettier_cmd = 'prettier --single-quote --trailing-comma all --stdin'
endif

function! prettier#execute(bang, user_input, start_line, end_line) abort
    let search = @/
    let view = winsaveview()
    let original_filetype = &filetype

    call s:prettier(a:bang, a:user_input, a:start_line, a:end_line)

    let @/ = search
    call winrestview(view)
    let &filetype = original_filetype
endfunction

function! s:better_echo(msg) abort
    if type(a:msg) != type('')
        echom 'prt: ' . string(a:msg)
    else
        echom 'pret: ' . a:msg
    endif
endfunction

function! s:prettier(bang, user_input, start_line, end_line) abort

    if !&modifiable
        return prettier#utils#warn('buffer not modifiable')
    endif

    let using_visual_selection = a:start_line != 1 || a:end_line != line('$')

    let inputs = split(a:user_input)
    if a:bang
        let &filetype = len(inputs) > 1 ? inputs[0] : a:user_input
    endif

    let stdin = getbufline(bufnr('%'), a:start_line, a:end_line)
    let original_buffer = getbufline(bufnr('%'), 1, '$')

    let stdout = split(system(get(g:, 'prettier_cmd'), l:stdin), '\n')

    call s:quickfixclear()

    if !v:shell_error
        " 1. append the lines that are before and after the formatterd content
        let lines_after = getbufline(bufnr('%'), a:end_line + 1, '$')
        let lines_before = getbufline(bufnr('%'), 1, a:start_line - 1)

        let new_buffer = lines_before + stdout + lines_after
        if new_buffer !=# original_buffer

            call s:deletelines(len(new_buffer), line('$'))

            call setline(1, new_buffer)
        endif
    else
      call s:quickfixerrors(stdout)
    endif
endfunction

function! s:quickfixerrors(out) abort
  let l:errors = []

  for line in a:out
    " matches:
    " stdin: SyntaxError: Unexpected token (2:8)
    let l:match = matchlist(line, '^stdin: \(.*\) (\(\d\{1,}\):\(\d\{1,}\)*)')
    if !empty(l:match)
      call add(l:errors, { 'bufnr': bufnr('%'),
                         \ 'text': match[1],
                         \ 'lnum': match[2],
                         \ 'col': match[3] })
    endif
  endfor

  if len(l:errors)
    call setqflist(l:errors)
    botright copen
  endif
endfunction

function! s:quickfixclear() abort
  call setqflist([])
  cclose
endfunction

function! s:deletelines(start, end) abort
    silent! execute a:start . ',' . a:end . 'delete _'
endfunction
