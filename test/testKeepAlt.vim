source helper.vim
call Setup()

enew
execute "normal! \<C-^>"
call Dump('buffer: '.bufname(''), 'keepAlt')
call Dump('altbuffer: '.bufname('#'), 'keepAlt')

normal ggx
doautocmd CursorHold
call Dump('altbuffer: '.bufname('#'), 'keepAlt')

