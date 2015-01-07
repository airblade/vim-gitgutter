" Primary functions {{{

function! gitgutter#all()
  for buffer_id in tabpagebuflist()
    let file = expand('#' . buffer_id . ':p')
    if !empty(file)
      call gitgutter#process_buffer(buffer_id, 0)
    endif
  endfor
endfunction

" bufnr: (integer) the buffer to process.
" realtime: (boolean) when truthy, do a realtime diff; otherwise do a disk-based diff.
function! gitgutter#process_buffer(bufnr, realtime)
  call gitgutter#utility#set_buffer(a:bufnr)
  if gitgutter#utility#is_active()
    if g:gitgutter_sign_column_always
      call gitgutter#sign#add_dummy_sign()
    endif
    try
      if !a:realtime || gitgutter#utility#has_fresh_changes()
        let diff = gitgutter#diff#run_diff(a:realtime || gitgutter#utility#has_unsaved_changes(), 1, 0)
        call gitgutter#hunk#set_hunks(gitgutter#diff#parse_diff(diff))
        let modified_lines = gitgutter#diff#process_hunks(gitgutter#hunk#hunks())

        if len(modified_lines) > g:gitgutter_max_signs
          call gitgutter#utility#warn('exceeded maximum number of signs (configured by g:gitgutter_max_signs).')
          call gitgutter#sign#clear_signs()
          return
        endif

        if g:gitgutter_signs || g:gitgutter_highlight_lines
          call gitgutter#sign#update_signs(modified_lines)
        endif

        call gitgutter#utility#save_last_seen_change()
      endif
    catch /diff failed/
      call gitgutter#hunk#reset()
    endtry
  else
    call gitgutter#hunk#reset()
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
      call gitgutter#utility#set_buffer(buffer_id)
      call gitgutter#sign#clear_signs()
      call gitgutter#sign#remove_dummy_sign(1)
      call gitgutter#hunk#reset()
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
  call gitgutter#highlight#define_sign_line_highlights()

  if !g:gitgutter_signs
    call gitgutter#sign#clear_signs()
    call gitgutter#sign#remove_dummy_sign(0)
  endif

  redraw!
endfunction

function! gitgutter#line_highlights_enable()
  let old_highlight_lines = g:gitgutter_highlight_lines

  let g:gitgutter_highlight_lines = 1
  call gitgutter#highlight#define_sign_line_highlights()

  if !old_highlight_lines && !g:gitgutter_signs
    call gitgutter#all()
  endif

  redraw!
endfunction

function! gitgutter#line_highlights_toggle()
  if g:gitgutter_highlight_lines
    call gitgutter#line_highlights_disable()
  else
    call gitgutter#line_highlights_enable()
  endif
endfunction

" }}}

" Signs {{{

function! gitgutter#signs_enable()
  let old_signs = g:gitgutter_signs

  let g:gitgutter_signs = 1
  call gitgutter#highlight#define_sign_text_highlights()

  if !old_signs && !g:gitgutter_highlight_lines
    call gitgutter#all()
  endif
endfunction

function! gitgutter#signs_disable()
  let g:gitgutter_signs = 0
  call gitgutter#highlight#define_sign_text_highlights()

  if !g:gitgutter_highlight_lines
    call gitgutter#sign#clear_signs()
    call gitgutter#sign#remove_dummy_sign(0)
  endif
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
  if gitgutter#utility#is_active()
    " Ensure the working copy of the file is up to date.
    " It doesn't make sense to stage a hunk otherwise.
    silent write

    " construct a diff
    let diff_for_hunk = gitgutter#diff#generate_diff_for_hunk(1, 1)

    " apply the diff
    call gitgutter#utility#system(gitgutter#utility#command_in_directory_of_file('git apply --cached --recount --allow-overlap - '), diff_for_hunk)

    " refresh gitgutter's view of buffer
    silent execute "GitGutter"
  endif
endfunction

function! gitgutter#revert_hunk()
  if gitgutter#utility#is_active()
    " Ensure the working copy of the file is up to date.
    " It doesn't make sense to stage a hunk otherwise.
    silent write

    " construct a diff
    let diff_for_hunk = gitgutter#diff#generate_diff_for_hunk(1, 1)

    " apply the diff
    call gitgutter#utility#system(gitgutter#utility#command_in_directory_of_file('git apply --reverse - '), diff_for_hunk)

    " reload file
    silent edit
  endif
endfunction

function! gitgutter#preview_hunk()
  if gitgutter#utility#is_active()
    silent write

    " construct a diff
    let diff_for_hunk = gitgutter#diff#generate_diff_for_hunk(0, 0)

    " preview the diff
    silent! wincmd P
    if !&previewwindow
      execute 'bo ' . &previewheight . ' new'
      set previewwindow
    endif

    setlocal noro modifiable filetype=diff buftype=nofile bufhidden=delete noswapfile
    execute "%delete_"
    call append(0, split(diff_for_hunk, "\n"))

    wincmd p
  endif
endfunction

" }}}
