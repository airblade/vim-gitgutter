source helper.vim

let tmpfile = tempname()
call system('touch '.tmpfile)
edit tmpfile
call DumpSigns('untrackedFileOutsideRepo')
