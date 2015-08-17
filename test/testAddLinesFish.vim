set shell=/usr/local/bin/fish
source helper.vim
call Setup()

normal ggo*
write
call DumpSigns('addLinesFish')
