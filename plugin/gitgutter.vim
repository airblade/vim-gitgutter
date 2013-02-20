if exists('g:loaded_gitgutter') || !executable('git') || &cp
  finish
endif
let g:loaded_gitgutter = 1

" Initialisation {{{

function! s:init()
  if !exists('g:gitgutter_initialised')
    call s:define_highlights()
    call s:define_signs()
    let g:gitgutter_initialised = 1
  endif
endfunction

function! s:define_highlights()
  highlight lineAdded    guifg=#009900 guibg=NONE ctermfg=2 ctermbg=NONE
  highlight lineModified guifg=#bbbb00 guibg=NONE ctermfg=3 ctermbg=NONE
  highlight lineRemoved  guifg=#ff2222 guibg=NONE ctermfg=1 ctermbg=NONE
endfunction

function! s:define_signs()
  sign define line_added    text=+ texthl=lineAdded
  sign define line_modified text=~ texthl=lineModified
  sign define line_removed  text=_ texthl=lineRemoved
endfunction

" }}}

" Utility {{{

function! s:current_file()
  return expand("%:p")
endfunction

function! s:is_in_a_git_repo()
  call system('git rev-parse > /dev/null 2>&1')
  return !v:shell_error
endfunction

function! s:is_tracked_by_git()
  call system('git ls-files --error-unmatch > /dev/null 2>&1 ' . shellescape(s:current_file()))
  return !v:shell_error
endfunction

" }}}

" Core logic {{{

function! s:run_diff()
  let cmd = 'git diff --no-ext-diff -U0 ' . shellescape(s:current_file())
  let diff = system(cmd)
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
    let from_line  = hunk[0]
    let from_count = hunk[1]
    let to_line    = hunk[2]
    let to_count   = hunk[3]
    " added
    if from_count == 0 && to_count > 0
      let offset = 0
      while offset < to_count
        let line_number = to_line + offset
        call add(modified_lines, [line_number, 'added'])
        let offset += 1
      endwhile
    " removed
    elseif from_count > 0 && to_count == 0
      " removed lines came after `to_line`.
      call add(modified_lines, [to_line, 'removed'])
    " modified
    else
      let offset = 0
      while offset < to_count
        let line_number = to_line + offset
        call add(modified_lines, [line_number, 'modified'])
        let offset += 1
      endwhile
    endif
  endfor
  return modified_lines
endfunction

function! s:clear_signs()
  sign unplace *
endfunction

function! s:show_signs(modified_lines)
  let file_name = s:current_file()
  for line in a:modified_lines
    let line_number = line[0]
    let type = line[1]
    " TODO: eugh
    if type ==? 'added'
      let name = 'line_added'
    elseif type ==? 'removed'
      let name = 'line_removed'
    elseif type ==? 'modified'
      let name = 'line_modified'
    endif
    exe ":sign place " . line_number . " line=" . line_number . " name=" . name . " file=" . file_name
  endfor
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
