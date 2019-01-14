function! gitgutter#fold#enable()
  call s:save_fold_state()

  setlocal foldexpr=gitgutter#fold#level(v:lnum)
  setlocal foldmethod=expr
  setlocal foldlevel=0
  setlocal foldenable

  call gitgutter#utility#setbufvar(bufnr(''), 'folded', 1)
endfunction


function! gitgutter#fold#disable()
  call s:restore_fold_state()
  call gitgutter#utility#setbufvar(bufnr(''), 'folded', 0)
endfunction


function! gitgutter#fold#toggle()
  if s:folded()
    call gitgutter#fold#disable()
  else
    call gitgutter#fold#enable()
  endif
endfunction


function! gitgutter#fold#level(lnum)
  return gitgutter#hunk#in_hunk(a:lnum) ? 0 : 1
endfunction


function! s:save_fold_state()
  call gitgutter#utility#setbufvar(bufnr(''), 'foldmethod', &foldmethod)
  if &foldmethod ==# 'manual'
    mkview
  endif
endfunction

function! s:restore_fold_state()
  let &foldmethod = gitgutter#utility#getbufvar(bufnr(''), 'foldmethod')
  if &foldmethod ==# 'manual'
    loadview
  else
    normal! zx
  endif
endfunction

function! s:folded()
  return gitgutter#utility#getbufvar(bufnr(''), 'folded')
endfunction

