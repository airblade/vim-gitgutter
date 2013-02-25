if exists('g:loaded_gitgutter') || !executable('git') || &cp
  finish
endif
let g:loaded_gitgutter = 1

" Initialisation {{{

function! s:init()
  if !exists('g:gitgutter_initialised')
    call s:define_highlights()
    call s:define_signs()

    " Vim doesn't namespace sign ids so every plugin shares the same
    " namespace.  Sign ids are simply integers so to avoid clashes with other
    " signs we guess at a clear run.
    "
    " Note also we currently never reset s:next_sign_id.
    let s:first_sign_id = 3000
    let s:next_sign_id = s:first_sign_id
    let s:sign_ids = {}  " key: filename, value: list of sign ids
    let s:other_signs = []

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

function! s:exists_current_file()
  return strlen(s:current_file()) > 0
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
  let cmd = 'git diff --no-ext-diff -U0 ' . shellescape(s:current_file()) .
        \ ' | grep -e "^@@ "'
  let diff = system(s:command_in_directory_of_current_file(cmd))
  return diff
endfunction

function! s:parse_diff(diff)
  let hunk_re = '^@@ -\(\d\+\),\?\(\d*\) +\(\d\+\),\?\(\d*\) @@'
  let hunks = []
  for line in split(a:diff, '\n')
    let matches    = matchlist(line, hunk_re)
    let from_line  = str2nr(matches[1])
    let from_count = (matches[2] == '') ? 1 : str2nr(matches[2])
    let to_line    = str2nr(matches[3])
    let to_count   = (matches[4] == '') ? 1 : str2nr(matches[4])
    call add(hunks, [from_line, from_count, to_line, to_count])
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
  if s:is_added(from_count, to_count)
    let offset = 0
    while offset < to_count
      let line_number = to_line + offset
      call add(modifications, [line_number, 'added'])
      let offset += 1
    endwhile
  elseif s:is_removed(from_count, to_count)
    " removed lines came after `to_line`.
    call add(modifications, [to_line, 'removed'])
  else  " modified
    let offset = 0
    while offset < to_count
      let line_number = to_line + offset
      call add(modifications, [line_number, 'modified'])
      let offset += 1
    endwhile
  endif
  return modifications
endfunction

function! s:is_added(from_count, to_count)
  return a:from_count == 0 && a:to_count > 0
endfunction

function! s:is_removed(from_count, to_count)
  return a:from_count > 0 && a:to_count == 0
endfunction

" }}}

" Sign processing {{{

function! s:clear_signs(file_name)
  if has_key(s:sign_ids, a:file_name)
    for id in s:sign_ids[a:file_name]
      exe ":sign unplace " . id . " file=" . a:file_name
    endfor
    let s:sign_ids[a:file_name] = []
  endif
endfunction

" This assumes there are no GitGutter signs in the current file.
" If this is untenable we could change the regexp to exclude GitGutter's
" signs.
function! s:find_other_signs(file_name)
  redir => signs
  silent exe ":sign place file=" . a:file_name
  redir END
  let s:other_signs = []
  for sign_line in split(signs, '\n')
    if sign_line =~ '^\s\+line'
      let matches = matchlist(sign_line, '^\s\+line=\(\d\+\)')
      let line_number = str2nr(matches[1])
      call add(s:other_signs, line_number)
    endif
  endfor
endfunction

function! s:show_signs(file_name, modified_lines)
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
    call s:add_sign(line_number, name, a:file_name)
  endfor
endfunction

function! s:add_sign(line_number, name, file_name)
  let id = s:next_sign_id()
  if !s:is_other_sign(a:line_number)  " Don't clobber other people's signs.
    exe ":sign place " . id . " line=" . a:line_number . " name=" . a:name . " file=" . a:file_name
    call s:remember_sign(id, a:file_name)
  endif
endfunction

function! s:next_sign_id()
  let next_id = s:next_sign_id
  let s:next_sign_id += 1
  return next_id
endfunction

function! s:remember_sign(id, file_name)
  if has_key(s:sign_ids, a:file_name)
    let sign_ids_for_current_file = s:sign_ids[a:file_name]
    call add(sign_ids_for_current_file, a:id)
  else
    let sign_ids_for_current_file = [a:id]
  endif
  let s:sign_ids[a:file_name] = sign_ids_for_current_file
endfunction

function! s:is_other_sign(line_number)
  return index(s:other_signs, a:line_number) == -1 ? 0 : 1
endfunction

" }}}

" Public interface {{{

function! GitGutter()
  if s:exists_current_file() && s:is_in_a_git_repo() && s:is_tracked_by_git()
    call s:init()
    let diff = s:run_diff()
    let hunks = s:parse_diff(diff)
    let modified_lines = s:process_hunks(hunks)
    let file_name = s:current_file()
    call s:clear_signs(file_name)
    call s:find_other_signs(file_name)
    call s:show_signs(file_name, modified_lines)
  endif
endfunction

augroup gitgutter
  autocmd!
  autocmd BufReadPost,BufWritePost,FileReadPost,FileWritePost * call GitGutter()
augroup END

" }}}

" vim:set et sw=2 fdm=marker:
