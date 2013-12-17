" number of lines [added, modified, removed]
let s:summary = [0, 0, 0]

function! hunk#summary()
  return s:summary
endfunction

function! hunk#reset()
  let s:summary = [0, 0, 0]  " TODO: is bling/airline expecting [-1, -1, -1]?
endfunction

function! hunk#increment_lines_added(count)
  let s:summary[0] += a:count
endfunction

function! hunk#increment_lines_modified(count)
  let s:summary[1] += a:count
endfunction

function! hunk#increment_lines_removed(count)
  let s:summary[2] += a:count
endfunction


