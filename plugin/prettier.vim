command! -nargs=? -bar -range=% -bang Prettier call prettier#execute(<bang>0, <q-args>, <line1>, <line2>)
