if exists('g:loaded_gitgutter') || !executable('git') || &cp
  finish
endif
let g:loaded_gitgutter = 1

" Initialisation {{{

function! s:init()
  if !exists('g:gitgutter_initialised')
    call s:define_highlights()
    call s:define_signs()

    let s:first_sign_id = 3000  " to avoid clashing with other signs
    let s:next_sign_id = s:first_sign_id
    let s:sign_ids = []

    let g:gitgutter_initialised = 1
  endif
endfunction

function! s:define_highlights()
  highlight lineAdded    guifg=#009900 guibg=NONE ctermfg=2 ctermbg=NONE
  highlight lineModified guifg=#bbbb00 guibg=NONE ctermfg=3 ctermbg=NONE
  highlight lineRemoved  guifg=#ff2222 guibg=NONE ctermfg=1 ctermbg=NONE
endfunction

function! s:define_signs()
  sign define GitGutterLineAdded    text=+ texthl=lineAdded
  sign define GitGutterLineModified text=~ texthl=lineModified
  sign define GitGutterLineRemoved  text=_ texthl=lineRemoved
endfunction

" }}}

" Utility {{{

function! s:current_file()
  return expand("%:p")
endfunction

function! s:directory_of_current_file()
  return expand("%:p:h")
endfunction

function! s:command_in_directory_of_current_file(cmd)
  return 'cd ' . s:directory_of_current_file() . ' && ' . a:cmd
endfunction

function! s:is_in_a_git_repo()
  let cmd = 'git rev-parse > /dev/null 2>&1'
  call system(s:command_in_directory_of_current_file(cmd))
  return !v:shell_error
endfunction

function! s:is_tracked_by_git()
  let cmd = 'git ls-files --error-unmatch > /dev/null 2>&1 ' . shellescape(s:current_file())
  call system(s:command_in_directory_of_current_file(cmd))
  return !v:shell_error
endfunction

" }}}

" Diff processing {{{

function! s:run_diff()
  let cmd = 'git diff --no-ext-diff -U0 ' . shellescape(s:current_file())
  let diff = system(s:command_in_directory_of_current_file(cmd))
  return diff
endfunction

function! s:parse_diff(diff)
  let hunk_re = '^@@ -\(\d\+\),\?\(\d*\) +\(\d\+\),\?\(\d*\) @@'
  let hunks = []
  for line in split(a:diff, '\n')
    if line =~ '^@@\s'
      let matches    = matchlist(line, hunk_re)
      let from_line  = str2nr(matches[1])
      let from_count = (matches[2] == '') ? 1 : str2nr(matches[2])
      let to_line    = str2nr(matches[3])
      let to_count   = (matches[4] == '') ? 1 : str2nr(matches[4])
      call add(hunks, [from_line, from_count, to_line, to_count])
    endif
  endfor
  return hunks
endfunction

function! s:process_hunks(hunks)
  let modified_lines = []
  for hunk in a:hunks
    call extend(modified_lines, s:process_hunk(hunk))
  endfor
  return modified_lines
endfunction

function! s:process_hunk(hunk)
  let modifications = []
  let from_line  = a:hunk[0]
  let from_count = a:hunk[1]
  let to_line    = a:hunk[2]
  let to_count   = a:hunk[3]
  " added
  if from_count == 0 && to_count > 0
    let offset = 0
    while offset < to_count
      let line_number = to_line + offset
      call add(modifications, [line_number, 'added'])
      let offset += 1
    endwhile
  " removed
  elseif from_count > 0 && to_count == 0
    " removed lines came after `to_line`.
    call add(modifications, [to_line, 'removed'])
  " modified
  else
    let offset = 0
    while offset < to_count
      let line_number = to_line + offset
      call add(modifications, [line_number, 'modified'])
      let offset += 1
    endwhile
  endif
  return modifications
endfunction

" }}}

" Sign processing {{{

function! s:clear_signs()
  for id in s:sign_ids
    exe ":sign unplace " . id
  endfor
  let s:sign_ids = []
  let s:next_sign_id = s:first_sign_id
endfunction

function! s:show_signs(modified_lines)
  let file_name = s:current_file()
  for line in a:modified_lines
    let line_number = line[0]
    let type = line[1]
    " TODO: eugh
    if type ==? 'added'
      let name = 'GitGutterLineAdded'
    elseif type ==? 'removed'
      let name = 'GitGutterLineRemoved'
    elseif type ==? 'modified'
      let name = 'GitGutterLineModified'
    endif
    call s:add_sign(line_number, name, file_name)
  endfor
endfunction

function! s:add_sign(line_number, name, file_name)
  let id = s:next_sign_id()
  exe ":sign place " . id . " line=" . a:line_number . " name=" . a:name . " file=" . a:file_name
  call s:remember_sign(id)
endfunction

function! s:next_sign_id()
  let next_id = s:next_sign_id
  let s:next_sign_id += 1
  return next_id
endfunction

function! s:remember_sign(id)
  call add(s:sign_ids, a:id)
endfunction

" }}}

" Public interface {{{

function! GitGutter()
  if s:is_in_a_git_repo() && s:is_tracked_by_git()
    call s:init()
    let diff = s:run_diff()
    let hunks = s:parse_diff(diff)
    let modified_lines = s:process_hunks(hunks)
    call s:clear_signs()
    call s:show_signs(modified_lines)
  endif
endfunction

" }}}

augroup gitgutter
  autocmd!
  autocmd BufReadPost,BufWritePost,FileReadPost,FileWritePost,BufEnter * call GitGutter()
augroup END

" vim:set et sw=2:
