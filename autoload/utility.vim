let s:file = ''

function! utility#is_active()
  return g:gitgutter_enabled && utility#exists_file()
endfunction

function! utility#slash()
  return !exists("+shellslash") || &shellslash ? '/' : '\'
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
  let repo_root_for_file = getbufvar(s:file, 'gitgutter_repo_root')
  if empty(repo_root_for_file)
    let dir = system(utility#command_in_directory_of_file('git rev-parse --show-toplevel'))
    let repo_root_for_file = substitute(dir, '\n$', '', '') . utility#slash()
    call setbufvar(s:file, 'gitgutter_repo_root', repo_root_for_file)
  endif
  return substitute(s:file, repo_root_for_file, '', '')
endfunction

" https://github.com/tpope/vim-dispatch/blob/bc415acd37187cbd6b417d92af40ba2c4b3b8775/autoload/dispatch/windows.vim#L8-L17
function! utility#escape(str)
  if &shellxquote ==# '"'
    return '"' . substitute(a:str, '"', '""', 'g') . '"'
  else
    let esc = exists('+shellxescape') ? &shellxescape : '"&|<>()@^'
    return &shellquote .
          \ substitute(a:str, '['.esc.']', '^&', 'g') .
          \ get({'(': ')', '"(': ')"'}, &shellquote, &shellquote)
  endif
endfunction

function! utility#command_in_directory_of_file(cmd)
  let directory_of_file = shellescape(fnamemodify(utility#file(), ':h'))
  return 'cd ' . directory_of_file . ' && ' . a:cmd
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
