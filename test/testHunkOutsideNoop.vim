source helper.vim
call Setup()

normal 5G

execute 'GitGutterStageHunk'
call DumpSigns('hunkOutsideNoopStageSigns')
call DumpGitDiffStaged('hunkHunkOutsideNoopStageGitDiffStaged')

execute 'GitGutterUndoHunk'
call DumpSigns('hunkOutsideNoopUndoSigns')
call DumpGitDiffStaged('hunkHunkOutsideNoopUndoGitDiffStaged')

