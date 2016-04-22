source helper.vim

let tmpfile = tempname()
call system('touch '.tmpfile)
execute 'edit '.tmpfile
call DumpSigns('untrackedFileOutsideRepo')
