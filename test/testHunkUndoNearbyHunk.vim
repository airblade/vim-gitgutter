source helper.vim
call Setup()

execute "normal! 2Gox\<CR>y\<CR>z"
normal 2jdd
normal k
execute 'GitGutterUndoHunk'
call DumpSigns('hunkUndoNearbySigns')
call DumpGitDiff('hunkUndoNearbyGitDiff')
