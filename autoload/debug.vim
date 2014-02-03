function! debug#debug()
  " Open a scratch buffer
  vsplit __GitGutter_Debug__
  normal! ggdG
  setlocal buftype=nofile
  setlocal bufhidden=delete
  setlocal noswapfile

  call debug#vim_version()
  call debug#separator()

  call debug#git_version()
  call debug#separator()

  call debug#option('shell')
  call debug#option('shellcmdflag')
  call debug#option('shellpipe')
  call debug#option('shellquote')
  call debug#option('shellredir')
  call debug#option('shellslash')
  call debug#option('shelltemp')
  call debug#option('shelltype')
  call debug#option('shellxescape')
  call debug#option('shellxquote')
endfunction


function! debug#separator()
  call debug#output('')
endfunction

function! debug#vim_version()
  redir => version_info
    silent execute 'version'
  redir END
  call debug#output(split(version_info, '\n')[0:2])
endfunction

function! debug#git_version()
  let v = system('git --version')
  call debug#output( substitute(v, '\n$', '', '') )
endfunction

function! debug#option(name)
  if exists('+' . a:name)
    let v = eval('&' . a:name)
    call debug#output(a:name . '=' . v)
    " redir => output
    "   silent execute "verbose set " . a:name . "?"
    " redir END
    " call debug#output(a:name . '=' . output)
  else
    call debug#output(a:name . ' [n/a]')
  end
endfunction

function! debug#output(text)
  call append(line('$'), a:text)
endfunction
