source helper.vim
call Setup()

" New hunk in the middle of the file
normal 5Go*
" Stage that hunk
execute 'GitGutterStageHunk'
" Add non-staged hunks
normal ggo*
normal GO*
" Switch to Staged mode
execute 'GitGutterStagedEnable'

" Should have a single staged hunk
call DumpSigns('staged')
