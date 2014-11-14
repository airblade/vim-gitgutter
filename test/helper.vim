set runtimepath+=../
source ../plugin/gitgutter.vim

function! Setup()
  edit! fixture.txt
  sign unplace *
endfunction

function! DumpSigns(filename)
  execute 'redir! > ' a:filename.'.actual'
    silent execute 'sign place'
  redir END
endfunction

function! DumpGitDiff(filename)
  call system('git diff --staged fixture.txt > '.a:filename.'.actual')
endfunction
