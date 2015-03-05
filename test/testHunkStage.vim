source helper.vim
call Setup()

normal 5Gi*
execute 'GitGutterStageHunk'
call DumpSigns('hunkStageSigns')
call DumpGitDiffStaged('hunkStageGitDiff')
