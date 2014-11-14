source helper.vim

let tmpfile = 'fileAddedToGit.tmp'
call system('touch '.tmpfile)
call system('git add '.tmpfile)
execute 'edit '.tmpfile
normal ihello
write
call DumpSigns('fileAddedToGit')

call system('git reset HEAD '.tmpfile)
call system('rm '.tmpfile)
