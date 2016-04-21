source helper.vim
call Setup()

normal 5Gi*
execute 'GitGutterUndoHunk'
call DumpSigns('hunkUndoSigns')
call DumpGitDiffStaged('hunkUndoGitDiff')
