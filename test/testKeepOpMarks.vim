source helper.vim
call Setup()

normal 5Go*
call Dump("'[ mark: ".join(getpos("'["), ','), 'keepOpMarks')
call Dump("'] mark: ".join(getpos("']"), ','), 'keepOpMarks')
doautocmd CursorHold
call Dump("'[ mark: ".join(getpos("'["), ','), 'keepOpMarks')
call Dump("'] mark: ".join(getpos("']"), ','), 'keepOpMarks')

