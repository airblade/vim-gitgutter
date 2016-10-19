source helper.vim
call Setup()

set shell=foo

normal 5Gi*
execute 'GitGutterUndoHunk'

call assert_equal('foo', &shell)  " NOTE: current test runner ignores v:errors so this line has no effect
set shell=/bin/bash
call DumpSigns('hunkUndoSigns')
call DumpGitDiffStaged('hunkUndoGitDiff')
