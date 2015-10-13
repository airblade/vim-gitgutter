source helper.vim

edit =fixture=.txt
normal ggo*
try
  write
  write
  call DumpSigns('filenameWithEquals')
finally
  call system('git reset HEAD =fixture=.txt')
  call system('git checkout =fixture=.txt')
endtry
