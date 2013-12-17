let s:grep_available = executable('grep')
let s:grep_command = ' | ' . (g:gitgutter_escape_grep ? '\grep' : 'grep') . ' -e "^@@ "'


function! diff#run_diff(realtime)
  if a:realtime
    let blob_name = ':./' . fnamemodify(utility#file(),':t')
    let blob_file = tempname()
    let cmd = 'git show ' . blob_name . ' > ' . blob_file . ' && diff -U0 ' . g:gitgutter_diff_args . ' ' . blob_file . ' - '
  else
    let cmd = 'git diff --no-ext-diff --no-color -U0 ' . g:gitgutter_diff_args . ' ' . shellescape(utility#file())
  endif
  if s:grep_available
    let cmd .= s:grep_command
  endif
  let cmd = utility#escape(cmd)
  if a:realtime
    if &fileformat ==# "dos"
      let eol = "\r\n"
    elseif &fileformat ==# "mac"
      let eol = "\r"
    else
      let eol = "\n"
    endif
    let buffer_contents = join(getline(1, '$'), eol) . eol
    let diff = system(utility#command_in_directory_of_file(cmd), buffer_contents)
  else
    let diff = system(utility#command_in_directory_of_file(cmd))
  endif
  return diff
endfunction

function! diff#parse_diff(diff)
  let hunk_re = '^@@ -\(\d\+\),\?\(\d*\) +\(\d\+\),\?\(\d*\) @@'
  let hunks = []
  for line in split(a:diff, '\n')
    let matches = matchlist(line, hunk_re)
    if len(matches) > 0
      let from_line  = str2nr(matches[1])
      let from_count = (matches[2] == '') ? 1 : str2nr(matches[2])
      let to_line    = str2nr(matches[3])
      let to_count   = (matches[4] == '') ? 1 : str2nr(matches[4])
      call add(hunks, [from_line, from_count, to_line, to_count])
    endif
  endfor
  return hunks
endfunction

function! diff#process_hunks(hunks)
  call hunk#reset()
  let modified_lines = []
  for hunk in a:hunks
    call extend(modified_lines, diff#process_hunk(hunk))
  endfor
  return modified_lines
endfunction

function! diff#process_hunk(hunk)
  let modifications = []
  let from_line  = a:hunk[0]
  let from_count = a:hunk[1]
  let to_line    = a:hunk[2]
  let to_count   = a:hunk[3]

  if diff#is_added(from_count, to_count)
    call diff#process_added(modifications, from_count, to_count, to_line)
    call hunk#increment_lines_added(to_count)

  elseif diff#is_removed(from_count, to_count)
    call diff#process_removed(modifications, from_count, to_count, to_line)
    call hunk#increment_lines_removed(from_count)

  elseif diff#is_modified(from_count, to_count)
    call diff#process_modified(modifications, from_count, to_count, to_line)
    call hunk#increment_lines_modified(to_count)

  elseif diff#is_modified_and_added(from_count, to_count)
    call diff#process_modified_and_added(modifications, from_count, to_count, to_line)
    call hunk#increment_lines_added(to_count - from_count)
    call hunk#increment_lines_modified(from_count)

  elseif diff#is_modified_and_removed(from_count, to_count)
    call diff#process_modified_and_removed(modifications, from_count, to_count, to_line)
    call hunk#increment_lines_modified(to_count)
    call hunk#increment_lines_removed(from_count - to_count)

  endif
  return modifications
endfunction

function! diff#is_added(from_count, to_count)
  return a:from_count == 0 && a:to_count > 0
endfunction

function! diff#is_removed(from_count, to_count)
  return a:from_count > 0 && a:to_count == 0
endfunction

function! diff#is_modified(from_count, to_count)
  return a:from_count > 0 && a:to_count > 0 && a:from_count == a:to_count
endfunction

function! diff#is_modified_and_added(from_count, to_count)
  return a:from_count > 0 && a:to_count > 0 && a:from_count < a:to_count
endfunction

function! diff#is_modified_and_removed(from_count, to_count)
  return a:from_count > 0 && a:to_count > 0 && a:from_count > a:to_count
endfunction

function! diff#process_added(modifications, from_count, to_count, to_line)
  let offset = 0
  while offset < a:to_count
    let line_number = a:to_line + offset
    call add(a:modifications, [line_number, 'added'])
    let offset += 1
  endwhile
endfunction

function! diff#process_removed(modifications, from_count, to_count, to_line)
  call add(a:modifications, [a:to_line, 'removed'])
endfunction

function! diff#process_modified(modifications, from_count, to_count, to_line)
  let offset = 0
  while offset < a:to_count
    let line_number = a:to_line + offset
    call add(a:modifications, [line_number, 'modified'])
    let offset += 1
  endwhile
endfunction

function! diff#process_modified_and_added(modifications, from_count, to_count, to_line)
  let offset = 0
  while offset < a:from_count
    let line_number = a:to_line + offset
    call add(a:modifications, [line_number, 'modified'])
    let offset += 1
  endwhile
  while offset < a:to_count
    let line_number = a:to_line + offset
    call add(a:modifications, [line_number, 'added'])
    let offset += 1
  endwhile
endfunction

function! diff#process_modified_and_removed(modifications, from_count, to_count, to_line)
  let offset = 0
  while offset < a:to_count
    let line_number = a:to_line + offset
    call add(a:modifications, [line_number, 'modified'])
    let offset += 1
  endwhile
  call add(a:modifications, [a:to_line + offset - 1, 'modified_removed'])
endfunction
