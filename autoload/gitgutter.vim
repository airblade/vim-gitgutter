" Primary functions {{{

function! gitgutter#all()
  for buffer_id in tabpagebuflist()
    let file = expand('#' . buffer_id . ':p')
    if !empty(file)
      call gitgutter#process_buffer(file, 0)
    endif
  endfor
endfunction

" file: (string) the file to process.
" realtime: (boolean) when truthy, do a realtime diff; otherwise do a disk-based diff.
function! gitgutter#process_buffer(file, realtime)
  call utility#set_file(a:file)
  if utility#is_active()
    if g:gitgutter_sign_column_always
      call sign#add_dummy_sign()
    endif
    try
      if !a:realtime || utility#has_fresh_changes(a:file)
        let diff = diff#run_diff(a:realtime || utility#has_unsaved_changes(a:file), 1)
        call hunk#set_hunks(diff#parse_diff(diff))
        let modified_lines = diff#process_hunks(hunk#hunks())

        if g:gitgutter_signs
          call sign#update_signs(a:file, modified_lines)
        endif

        call utility#save_last_seen_change(a:file)
      endif
    catch /diff failed/
      call hunk#reset()
    endtry
  else
    call hunk#reset()
  endif
endfunction

function! gitgutter#disable()
  " get list of all buffers (across all tabs)
  let buflist = []
  for i in range(tabpagenr('$'))
    call extend(buflist, tabpagebuflist(i + 1))
  endfor

  for buffer_id in buflist
    let file = expand('#' . buffer_id . ':p')
    if !empty(file)
      call utility#set_file(file)
      call sign#clear_signs(utility#file())
      call sign#remove_dummy_sign(1)
      call hunk#reset()
    endif
  endfor

  let g:gitgutter_enabled = 0
endfunction

function! gitgutter#enable()
  let g:gitgutter_enabled = 1
  call gitgutter#all()
endfunction

function! gitgutter#toggle()
  if g:gitgutter_enabled
    call gitgutter#disable()
  else
    call gitgutter#enable()
  endif
endfunction

" }}}

" Line highlights {{{

function! gitgutter#line_highlights_disable()
  let g:gitgutter_highlight_lines = 0
  call highlight#define_sign_line_highlights()
  redraw!
endfunction

function! gitgutter#line_highlights_enable()
  let g:gitgutter_highlight_lines = 1
  call highlight#define_sign_line_highlights()
  redraw!
endfunction

function! gitgutter#line_highlights_toggle()
  let g:gitgutter_highlight_lines = !g:gitgutter_highlight_lines
  call highlight#define_sign_line_highlights()
  redraw!
endfunction

" }}}

" Signs {{{

function! gitgutter#signs_enable()
  let g:gitgutter_signs = 1
  call gitgutter#all()
endfunction

function! gitgutter#signs_disable()
  let g:gitgutter_signs = 0
  call sign#clear_signs(utility#file())
  call sign#remove_dummy_sign(0)
endfunction

function! gitgutter#signs_toggle()
  if g:gitgutter_signs
    call gitgutter#signs_disable()
  else
    call gitgutter#signs_enable()
  endif
endfunction

" }}}

" Hunks {{{

function! gitgutter#stage_hunk()
  if utility#is_active()
    " Ensure the working copy of the file is up to date.
    " It doesn't make sense to stage a hunk otherwise.
    silent write

    " find current hunk
    let current_hunk = hunk#current_hunk()
    if empty(current_hunk)
      return
    endif

    " construct a diff
    let diff_for_hunk = diff#generate_diff_for_hunk(current_hunk, 1)

    " apply the diff
    call system(utility#command_in_directory_of_file('git apply --cached --unidiff-zero - '), diff_for_hunk)

    " refresh gitgutter's view of buffer
    silent execute "GitGutter"
  endif
endfunction

function! gitgutter#revert_hunk()
  if utility#is_active()
    " Ensure the working copy of the file is up to date.
    " It doesn't make sense to stage a hunk otherwise.
    silent write

    " find current hunk
    let current_hunk = hunk#current_hunk()
    if empty(current_hunk)
      return
    endif

    " construct a diff
    let diff_for_hunk = diff#generate_diff_for_hunk(current_hunk, 1)

    " apply the diff
    call system(utility#command_in_directory_of_file('git apply --reverse --unidiff-zero - '), diff_for_hunk)

    " reload file
    silent edit
  endif
endfunction

function! gitgutter#preview_hunk()
  if utility#is_active()
    silent write

    " find current hunk
    let current_hunk = hunk#current_hunk()
    if empty(current_hunk)
      return
    endif

    " construct a diff
    let diff_for_hunk = diff#generate_diff_for_hunk(current_hunk, 0)

    " preview the diff
    silent! wincmd P
    if !&previewwindow
      execute 'bo ' . &previewheight . ' new'
      set previewwindow
      setlocal filetype=diff buftype=nowrite
    endif

    execute "%delete_"
    call append(0, split(diff_for_hunk, "\n"))

    wincmd p
  endif
endfunction

" }}}
