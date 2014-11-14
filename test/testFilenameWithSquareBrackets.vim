source helper.vim

edit fix[tu]re.txt
normal ggo*
write
call DumpSigns('filenameWithSquareBrackets')

call system('git reset HEAD fix[tu]re.txt')
call system('git checkout fix[tu]re.txt')
