source helper.vim
call Setup()

normal 5Go*
call Dump("modified: ".getbufvar('', '&modified'), 'keepModified')
doautocmd CursorHold
call Dump("modified: ".getbufvar('', '&modified'), 'keepModified')

