source helper.vim

let tmpfile = 'symlink'
call system('ln -nfs fixture.txt '.tmpfile)
execute 'edit '.tmpfile
execute '6d'
write
call DumpSigns('followSymlink')

call system('rm '.tmpfile)
