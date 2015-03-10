" number of lines [added, modified, removed]
let s:summary = [0, 0, 0]
let s:hunks = []

function! gitgutter#hunk#set_hunks(hunks)
  let s:hunks = a:hunks
endfunction

function! gitgutter#hunk#hunks()
  return s:hunks
endfunction

function! gitgutter#hunk#summary()
  return s:summary
endfunction

function! gitgutter#hunk#reset()
  let s:summary = [0, 0, 0]
endfunction

function! gitgutter#hunk#increment_lines_added(count)
  let s:summary[0] += a:count
endfunction

function! gitgutter#hunk#increment_lines_modified(count)
  let s:summary[1] += a:count
endfunction

function! gitgutter#hunk#increment_lines_removed(count)
  let s:summary[2] += a:count
endfunction

function! gitgutter#hunk#next_hunk(count)
  if gitgutter#utility#is_active()
    let current_line = line('.')
    let hunk_count = 0
    for hunk in s:hunks
      if hunk[2] > current_line
        let hunk_count += 1
        if hunk_count == a:count
          execute 'normal!' hunk[2] . 'G'
          return
        endif
      endif
    endfor
    echo 'No more hunks'
  endif
endfunction

function! gitgutter#hunk#prev_hunk(count)
  if gitgutter#utility#is_active()
    let current_line = line('.')
    let hunk_count = 0
    for hunk in reverse(copy(s:hunks))
      if hunk[2] < current_line
        let hunk_count += 1
        if hunk_count == a:count
          let target = hunk[2] == 0 ? 1 : hunk[2]
          execute 'normal!' target . 'G'
          return
        endif
      endif
    endfor
    echo 'No previous hunks'
  endif
endfunction

" Returns the hunk the cursor is currently in or an empty list if the cursor
" isn't in a hunk.
function! gitgutter#hunk#current_hunk()
  let current_hunk = []

  for hunk in s:hunks
    if gitgutter#hunk#cursor_in_hunk(hunk)
      let current_hunk = hunk
      break
    endif
  endfor

  return current_hunk
endfunction

function! gitgutter#hunk#cursor_in_hunk(hunk)
  let current_line = line('.')

  if current_line == 1 && a:hunk[2] == 0
    return 1
  endif

  if current_line >= a:hunk[2] && current_line < a:hunk[2] + (a:hunk[3] == 0 ? 1 : a:hunk[3])
    return 1
  endif

  return 0
endfunction

" Returns the number of lines the current hunk is offset from where it would
" be if any changes above it in the file didn't exist.
function! gitgutter#hunk#line_adjustment_for_current_hunk()
  let adj = 0
  for hunk in s:hunks
    if gitgutter#hunk#cursor_in_hunk(hunk)
      break
    else
      let adj += hunk[1] - hunk[3]
    endif
  endfor
  return adj
endfunction
