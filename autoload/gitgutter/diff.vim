let s:grep_available = executable('grep')
if s:grep_available
  let s:grep_command = ' | '.(g:gitgutter_escape_grep ? '\grep' : 'grep')
  let s:grep_help = gitgutter#utility#system('grep --help')
  if s:grep_help =~# '--color'
    let s:grep_command .= ' --color=never'
  endif
  let s:grep_command .= ' -e '.gitgutter#utility#shellescape('^@@ ')
endif
let s:hunk_re = '^@@ -\(\d\+\),\?\(\d*\) +\(\d\+\),\?\(\d*\) @@'


function! gitgutter#diff#run_diff(realtime, use_external_grep)
  " Wrap compound commands in parentheses to make Windows happy.
  let cmd = '('

  let bufnr = gitgutter#utility#bufnr()
  let tracked = getbufvar(bufnr, 'gitgutter_tracked')  " i.e. tracked by git
  if !tracked
    let cmd .= 'git ls-files --error-unmatch '.gitgutter#utility#shellescape(gitgutter#utility#filename()).' && ('
  endif

  if a:realtime
    let blob_name = ':'.gitgutter#utility#shellescape(gitgutter#utility#file_relative_to_repo_root())
    let blob_file = tempname()
    let buff_file = tempname()
    let extension = gitgutter#utility#extension()
    if !empty(extension)
      let blob_file .= '.'.extension
      let buff_file .= '.'.extension
    endif
    let cmd .= 'git show '.blob_name.' > '.blob_file.' && '

    " Writing the whole buffer resets the '[ and '] marks and also the
    " 'modified' flag (if &cpoptions includes '+').  These are unwanted
    " side-effects so we save and restore the values ourselves.
    let modified      = getbufvar(bufnr, "&mod")
    let op_mark_start = getpos("'[")
    let op_mark_end   = getpos("']")

    execute 'keepalt silent write' buff_file

    call setbufvar(bufnr, "&mod", modified)
    call setpos("'[", op_mark_start)
    call setpos("']", op_mark_end)
  endif

  let cmd .= 'git diff --no-ext-diff --no-color -U0 '.g:gitgutter_diff_args.' -- '
  if a:realtime
    let cmd .= blob_file.' '.buff_file
  else
    let cmd .= gitgutter#utility#shellescape(gitgutter#utility#filename())
  endif

  if a:use_external_grep && s:grep_available
    let cmd .= s:grep_command
  endif

  if (a:use_external_grep && s:grep_available) || a:realtime
    " grep exits with 1 when no matches are found; diff exits with 1 when
    " differences are found.  However we want to treat non-matches and
    " differences as non-erroneous behaviour; so we OR the command with one
    " which always exits with success (0).
    let cmd.= ' || exit 0'
  endif

  let cmd .= ')'

  if !tracked
    let cmd .= ')'
  endif

  let diff = gitgutter#utility#system(gitgutter#utility#command_in_directory_of_file(cmd))

  if a:realtime
    call delete(blob_file)
    call delete(buff_file)
  endif

  if gitgutter#utility#shell_error()
    " A shell error indicates the file is not tracked by git (unless something bizarre is going on).
    throw 'diff failed'
  endif

  if !tracked
    call setbufvar(bufnr, 'gitgutter_tracked', 1)
  endif

  return diff
endfunction

function! gitgutter#diff#parse_diff(diff)
  let hunks = []
  for line in split(a:diff, '\n')
    let hunk_info = gitgutter#diff#parse_hunk(line)
    if len(hunk_info) == 4
      call add(hunks, hunk_info)
    endif
  endfor
  return hunks
endfunction

function! gitgutter#diff#parse_hunk(line)
  let matches = matchlist(a:line, s:hunk_re)
  if len(matches) > 0
    let from_line  = str2nr(matches[1])
    let from_count = (matches[2] == '') ? 1 : str2nr(matches[2])
    let to_line    = str2nr(matches[3])
    let to_count   = (matches[4] == '') ? 1 : str2nr(matches[4])
    return [from_line, from_count, to_line, to_count]
  else
    return []
  end
endfunction

function! gitgutter#diff#process_hunks(hunks)
  call gitgutter#hunk#reset()
  let modified_lines = []
  for hunk in a:hunks
    call extend(modified_lines, gitgutter#diff#process_hunk(hunk))
  endfor
  return modified_lines
endfunction

" Returns [ [<line_number (number)>, <name (string)>], ...]
function! gitgutter#diff#process_hunk(hunk)
  let modifications = []
  let from_line  = a:hunk[0]
  let from_count = a:hunk[1]
  let to_line    = a:hunk[2]
  let to_count   = a:hunk[3]

  if gitgutter#diff#is_added(from_count, to_count)
    call gitgutter#diff#process_added(modifications, from_count, to_count, to_line)
    call gitgutter#hunk#increment_lines_added(to_count)

  elseif gitgutter#diff#is_removed(from_count, to_count)
    call gitgutter#diff#process_removed(modifications, from_count, to_count, to_line)
    call gitgutter#hunk#increment_lines_removed(from_count)

  elseif gitgutter#diff#is_modified(from_count, to_count)
    call gitgutter#diff#process_modified(modifications, from_count, to_count, to_line)
    call gitgutter#hunk#increment_lines_modified(to_count)

  elseif gitgutter#diff#is_modified_and_added(from_count, to_count)
    call gitgutter#diff#process_modified_and_added(modifications, from_count, to_count, to_line)
    call gitgutter#hunk#increment_lines_added(to_count - from_count)
    call gitgutter#hunk#increment_lines_modified(from_count)

  elseif gitgutter#diff#is_modified_and_removed(from_count, to_count)
    call gitgutter#diff#process_modified_and_removed(modifications, from_count, to_count, to_line)
    call gitgutter#hunk#increment_lines_modified(to_count)
    call gitgutter#hunk#increment_lines_removed(from_count - to_count)

  endif
  return modifications
endfunction

function! gitgutter#diff#is_added(from_count, to_count)
  return a:from_count == 0 && a:to_count > 0
endfunction

function! gitgutter#diff#is_removed(from_count, to_count)
  return a:from_count > 0 && a:to_count == 0
endfunction

function! gitgutter#diff#is_modified(from_count, to_count)
  return a:from_count > 0 && a:to_count > 0 && a:from_count == a:to_count
endfunction

function! gitgutter#diff#is_modified_and_added(from_count, to_count)
  return a:from_count > 0 && a:to_count > 0 && a:from_count < a:to_count
endfunction

function! gitgutter#diff#is_modified_and_removed(from_count, to_count)
  return a:from_count > 0 && a:to_count > 0 && a:from_count > a:to_count
endfunction

function! gitgutter#diff#process_added(modifications, from_count, to_count, to_line)
  let offset = 0
  while offset < a:to_count
    let line_number = a:to_line + offset
    call add(a:modifications, [line_number, 'added'])
    let offset += 1
  endwhile
endfunction

function! gitgutter#diff#process_removed(modifications, from_count, to_count, to_line)
  if a:to_line == 0
    call add(a:modifications, [1, 'removed_first_line'])
  else
    call add(a:modifications, [a:to_line, 'removed'])
  endif
endfunction

function! gitgutter#diff#process_modified(modifications, from_count, to_count, to_line)
  let offset = 0
  while offset < a:to_count
    let line_number = a:to_line + offset
    call add(a:modifications, [line_number, 'modified'])
    let offset += 1
  endwhile
endfunction

function! gitgutter#diff#process_modified_and_added(modifications, from_count, to_count, to_line)
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

function! gitgutter#diff#process_modified_and_removed(modifications, from_count, to_count, to_line)
  let offset = 0
  while offset < a:to_count
    let line_number = a:to_line + offset
    call add(a:modifications, [line_number, 'modified'])
    let offset += 1
  endwhile
  let a:modifications[-1] = [a:to_line + offset - 1, 'modified_removed']
endfunction

" Generates a zero-context diff for the current hunk.
"
" type - stage | revert | preview
function! gitgutter#diff#generate_diff_for_hunk(type)
  " Although (we assume) diff is up to date, we don't store it anywhere so we
  " have to regenerate it now...
  let diff = gitgutter#diff#run_diff(0, 0)
  let diff_for_hunk = gitgutter#diff#discard_hunks(diff, a:type == 'stage' || a:type == 'revert')

  if a:type == 'stage' || a:type == 'revert'
    let diff_for_hunk = gitgutter#diff#adjust_hunk_summary(diff_for_hunk, a:type == 'stage')
  endif

  return diff_for_hunk
endfunction

" Returns the diff with all hunks discarded except the current.
"
" diff        - the diff to process
" keep_header - truthy to keep the diff header and hunk summary, falsy to discard it
function! gitgutter#diff#discard_hunks(diff, keep_header)
  let modified_diff = []
  let keep_line = a:keep_header
  for line in split(a:diff, '\n')
    let hunk_info = gitgutter#diff#parse_hunk(line)
    if len(hunk_info) == 4  " start of new hunk
      let keep_line = gitgutter#hunk#cursor_in_hunk(hunk_info)
    endif
    if keep_line
      call add(modified_diff, line)
    endif
  endfor

  if a:keep_header
    return join(modified_diff, "\n") . "\n"
  else
    " Discard hunk summary too.
    return join(modified_diff[1:], "\n") . "\n"
  endif
endfunction

" Adjust hunk summary (from's / to's line number) to ignore changes above/before this one.
"
" diff_for_hunk - a diff containing only the hunk of interest
" staging       - truthy if the hunk is to be staged, falsy if it is to be reverted
"
" TODO: push this down to #discard_hunks?
function! gitgutter#diff#adjust_hunk_summary(diff_for_hunk, staging)
  let line_adjustment = gitgutter#hunk#line_adjustment_for_current_hunk()
  let adj_diff = []
  for line in split(a:diff_for_hunk, '\n')
    if match(line, s:hunk_re) != -1
      if a:staging
        " increment 'to' line number
        let line = substitute(line, '+\@<=\(\d\+\)', '\=submatch(1)+line_adjustment', '')
      else
        " decrement 'from' line number
        let line = substitute(line, '-\@<=\(\d\+\)', '\=submatch(1)-line_adjustment', '')
      endif
    endif
    call add(adj_diff, line)
  endfor
  return join(adj_diff, "\n") . "\n"
endfunction

