source helper.vim
call Setup()

normal 5Gi*
call system('git checkout -b fixture.txt')
write
call DumpSigns('ambiguousFile')

call system('git checkout - && git branch -d fixture.txt')
