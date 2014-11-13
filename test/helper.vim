set runtimepath+=../
source ../plugin/gitgutter.vim

function! Setup()
  call system('git checkout fixture.txt')
  edit! fixture.txt
  sign unplace *
endfunction

function! DumpSigns(filename)
  execute 'redir! > ' a:filename.'.out'
    silent execute 'sign place'
  redir END
endfunction

