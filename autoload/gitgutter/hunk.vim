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
  let s:summary = [0, 0, 0]  " TODO: is bling/airline expecting [-1, -1, -1]?
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
          break
        endif
      endif
    endfor
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
          break
        endif
      endif
    endfor
  endif
endfunction

" Returns the hunk the cursor is currently in or 0 if the cursor isn't in a
" hunk.
function! gitgutter#hunk#current_hunk()
  let current_hunk = []
  let current_line = line('.')

  for hunk in s:hunks
    if current_line == 1 && hunk[2] == 0
      let current_hunk = hunk
      break
    endif

    if current_line >= hunk[2] && current_line < hunk[2] + (hunk[3] == 0 ? 1 : hunk[3])
      let current_hunk = hunk
      break
    endif
  endfor

  if len(current_hunk) == 4
    return current_hunk
  endif
endfunction

