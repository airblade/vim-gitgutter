set runtimepath+=../
source ../plugin/gitgutter.vim

function! Setup()
  call system('git reset HEAD fixture.txt')
  call system('git checkout fixture.txt')
  edit! fixture.txt
  sign unplace *
endfunction

function! DumpSigns(filename)
  execute 'redir! > ' a:filename.'.out'
    silent execute 'sign place'
  redir END
endfunction

function! DumpGitDiff(filename)
  call system('git diff --staged fixture.txt > '.a:filename.'.out')
endfunction
