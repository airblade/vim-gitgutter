source helper.vim
call Setup()

execute "normal! 2Gox\<CR>y\<CR>z"
normal 2jdd
normal k
execute 'GitGutterStageHunk'
call DumpSigns('hunkStageNearbySigns')
call DumpGitDiff('hunkStageNearbyGitDiff')
call DumpGitDiffStaged('hunkStageNearbyGitDiffStaged')
