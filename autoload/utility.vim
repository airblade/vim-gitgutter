let s:file = ''

function! utility#is_active()
  return g:gitgutter_enabled && utility#exists_file()
endfunction

" A replacement for the built-in `shellescape(arg)`.
"
" Recent versions of Vim handle shell escaping pretty well.  However older
" versions aren't as good.  This attempts to do the right thing.
"
" See:
" https://github.com/tpope/vim-fugitive/blob/8f0b8edfbd246c0026b7a2388e1d883d579ac7f6/plugin/fugitive.vim#L29-L37
function! utility#shellescape(arg)
  if a:arg =~ '^[A-Za-z0-9_/.-]\+$'
    return a:arg
  elseif &shell =~# 'cmd'
    return '"' . substitute(substitute(a:arg, '"', '""', 'g'), '%', '"%"', 'g') . '"'
  else
    return shellescape(a:arg)
  endif
endfunction

function! utility#current_file()
  return expand('%:p')
endfunction

function! utility#set_file(file)
  let s:file = a:file
endfunction

function! utility#file()
  return s:file
endfunction

function! utility#filename()
  return fnamemodify(s:file, ':t')
endfunction

function! utility#directory_of_file()
  return fnamemodify(s:file, ':h')
endfunction

function! utility#exists_file()
  return filereadable(utility#file())
endfunction

function! utility#has_unsaved_changes(file)
  return getbufvar(a:file, "&mod")
endfunction

function! utility#has_fresh_changes(file)
  return getbufvar(a:file, 'changedtick') != getbufvar(a:file, 'gitgutter_last_tick')
endfunction

function! utility#save_last_seen_change(file)
  call setbufvar(a:file, 'gitgutter_last_tick', getbufvar(a:file, 'changedtick'))
endfunction

function! utility#buffer_contents()
  if &fileformat ==# "dos"
    let eol = "\r\n"
  elseif &fileformat ==# "mac"
    let eol = "\r"
  else
    let eol = "\n"
  endif
  return join(getbufline(s:file, 1, '$'), eol) . eol
endfunction

function! utility#file_relative_to_repo_root()
  let file_path_relative_to_repo_root = getbufvar(s:file, 'gitgutter_repo_relative_path')
  if empty(file_path_relative_to_repo_root)
    let dir_path_relative_to_repo_root = system(utility#command_in_directory_of_file('git rev-parse --show-prefix'))
    let dir_path_relative_to_repo_root = utility#strip_trailing_new_line(dir_path_relative_to_repo_root)
    let file_path_relative_to_repo_root = dir_path_relative_to_repo_root . utility#filename()
    call setbufvar(s:file, 'gitgutter_repo_relative_path', file_path_relative_to_repo_root)
  endif
  return file_path_relative_to_repo_root
endfunction

function! utility#command_in_directory_of_file(cmd)
  return 'cd ' . utility#shellescape(utility#directory_of_file()) . ' && ' . a:cmd
endfunction

function! utility#highlight_name_for_change(text)
  if a:text ==# 'added'
    return 'GitGutterLineAdded'
  elseif a:text ==# 'removed'
    return 'GitGutterLineRemoved'
  elseif a:text ==# 'modified'
    return 'GitGutterLineModified'
  elseif a:text ==# 'modified_removed'
    return 'GitGutterLineModifiedRemoved'
  endif
endfunction

function utility#strip_trailing_new_line(line)
  return substitute(a:line, '\n$', '', '')
endfunction
