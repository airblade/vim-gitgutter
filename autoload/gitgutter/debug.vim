let s:log_file = expand('<sfile>:p:h:h:h').'/'.'gitgutter.log'

function! gitgutter#debug#debug()
  " Open a scratch buffer
  vsplit __GitGutter_Debug__
  normal! ggdG
  setlocal buftype=nofile
  setlocal bufhidden=delete
  setlocal noswapfile

  call gitgutter#debug#vim_version()
  call gitgutter#debug#separator()

  call gitgutter#debug#git_version()
  call gitgutter#debug#separator()

  call gitgutter#debug#grep_version()
  call gitgutter#debug#separator()

  call gitgutter#debug#option('updatetime')
  call gitgutter#debug#option('shell')
  call gitgutter#debug#option('shellcmdflag')
  call gitgutter#debug#option('shellpipe')
  call gitgutter#debug#option('shellquote')
  call gitgutter#debug#option('shellredir')
  call gitgutter#debug#option('shellslash')
  call gitgutter#debug#option('shelltemp')
  call gitgutter#debug#option('shelltype')
  call gitgutter#debug#option('shellxescape')
  call gitgutter#debug#option('shellxquote')
endfunction


function! gitgutter#debug#separator()
  call gitgutter#debug#output('')
endfunction

function! gitgutter#debug#vim_version()
  redir => version_info
    silent execute 'version'
  redir END
  call gitgutter#debug#output(split(version_info, '\n')[0:2])
endfunction

function! gitgutter#debug#git_version()
  let v = system('git --version')
  call gitgutter#debug#output( substitute(v, '\n$', '', '') )
endfunction

function! gitgutter#debug#grep_version()
  let v = system('grep --version')
  call gitgutter#debug#output( substitute(v, '\n$', '', '') )

  let v = system('grep --help')
  call gitgutter#debug#output( substitute(v, '\%x00', '', 'g') )
endfunction

function! gitgutter#debug#option(name)
  if exists('+' . a:name)
    let v = eval('&' . a:name)
    call gitgutter#debug#output(a:name . '=' . v)
    " redir => output
    "   silent execute "verbose set " . a:name . "?"
    " redir END
    " call gitgutter#debug#output(a:name . '=' . output)
  else
    call gitgutter#debug#output(a:name . ' [n/a]')
  end
endfunction

function! gitgutter#debug#output(text)
  call append(line('$'), a:text)
endfunction

" assumes optional args are calling function's optional args
function! gitgutter#debug#log(message, ...)
  if g:gitgutter_log
    execute 'redir >> '.s:log_file
      " callers excluding this function
      silent echo "\n".expand('<sfile>')[:-22].':'
      silent echo type(a:message) == 1 ? join(split(a:message, '\n'),"\n") : a:message
      if a:0 && !empty(a:1)
        for msg in a:000
          silent echo type(msg) == 1 ? join(split(msg, '\n'),"\n") : msg
        endfor
      endif
    redir END
  endif
endfunction

