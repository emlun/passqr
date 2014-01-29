set tabstop=4 shiftwidth=4 expandtab
au FileType markdown setlocal textwidth=80

" Recognize *.bash-completion and *.conf as shell script
au BufRead,BufNewFile *.bash-completion set filetype=sh
au BufRead,BufNewFile *.conf set filetype=sh
