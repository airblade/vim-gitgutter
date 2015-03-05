source helper.vim
call Setup()

normal 5G

execute 'GitGutterStageHunk'
call DumpSigns('hunkOutsideNoopStageSigns')
call DumpGitDiffStaged('hunkHunkOutsideNoopStageGitDiffStaged')

execute 'GitGutterRevertHunk'
call DumpSigns('hunkOutsideNoopRevertSigns')
call DumpGitDiffStaged('hunkHunkOutsideNoopRevertGitDiffStaged')

