source helper.vim
call Setup()

normal 5Gi*
execute 'GitGutterRevertHunk'
call DumpSigns('hunkRevertSigns')
call DumpGitDiff('hunkRevertGitDiff')
