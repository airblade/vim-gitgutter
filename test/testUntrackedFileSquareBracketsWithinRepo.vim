source helper.vim

let tmpfile = '[un]trackedFileWithinRepo.tmp'
call system('touch '.tmpfile)
execute 'edit '.tmpfile
normal ggo*
doautocmd CursorHold
call DumpSigns('untrackedFileSquareBracketsWithinRepo')

call system('rm '.tmpfile)
