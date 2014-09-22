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
