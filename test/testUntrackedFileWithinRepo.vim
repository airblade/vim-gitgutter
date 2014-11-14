source helper.vim

let tmpfile = 'untrackedFileWithinRepo.tmp'
call system('touch '.tmpfile)
edit tmpfile
call DumpSigns('untrackedFileWithinRepo')

call system('rm '.tmpfile)
