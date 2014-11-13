source helper.vim
call Setup()

execute "normal 5GoX\<CR>Y"
write
execute '6d'
write
call DumpSigns('orphanedSigns')
