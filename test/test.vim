set runtimepath+=../
source ../plugin/gitgutter.vim


function! s:setup()
  call system('git checkout fixture.txt')
  edit! fixture.txt
  sign unplace *
endfunction

function! s:dumpSigns(filename)
  execute 'redir! > ' a:filename.'.out'
    silent execute 'sign place'
  redir END
endfunction


"
" The tests.
"

function! s:testNoModifications()
  call s:setup()
  call s:dumpSigns('noModifications')
endfunction

function! s:testAddLines()
  call s:setup()
  normal ggo*
  write
  call s:dumpSigns('addLines')
endfunction

function! s:testModifyLines()
  call s:setup()
  normal ggi*
  write
  call s:dumpSigns('modifyLines')
endfunction

function! s:testRemoveLines()
  call s:setup()
  execute '5d'
  write
  call s:dumpSigns('removeLines')
endfunction

function! s:testRemoveFirstLines()
  call s:setup()
  execute '1d'
  write
  call s:dumpSigns('removeFirstLines')
endfunction

function! s:testOrphanedSigns()
  call s:setup()
  execute "normal 5GoX\<CR>Y"
  write
  execute '6d'
  write
  call s:dumpSigns('orphanedSigns')
endfunction

"
" Execute the tests.
"

call s:testNoModifications()
call s:testAddLines()
call s:testModifyLines()
call s:testRemoveLines()
call s:testRemoveFirstLines()
call s:testOrphanedSigns()


"
" Cleanup.
"

call system('git checkout fixture.txt')
quit!

