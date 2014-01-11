let s:file = ''

function! utility#is_active()
  return g:gitgutter_enabled && utility#exists_file() && utility#is_tracked_by_git()
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

function! utility#directory_of_file()
  return shellescape(fnamemodify(utility#file(), ':h'))
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

" https://github.com/tpope/vim-dispatch/blob/9cdd05a87f8a47120335be03dfcd8358544221cd/autoload/dispatch/windows.vim#L8-L17
function! utility#escape(str)
  if &shellxquote ==# '"'
    return '"' . substitute(a:str, '"', '""', 'g') . '"'
  else
    let esc = exists('+shellxescape') ? &shellxescape : '"&|<>()@^'
    return &shellquote .
          \ substitute(a:str, '['.esc.']', '&', 'g') .
          \ get({'(': ')', '"(': ')"'}, &shellquote, &shellquote)
  endif
endfunction

function! utility#discard_stdout_and_stderr()
  if !exists('utility#discard')
    if &shellredir ==? '>%s 2>&1'
      let utility#discard = ' > /dev/null 2>&1'
    else
      let utility#discard = ' >& /dev/null'
    endif
  endif
  return utility#discard
endfunction

function! utility#command_in_directory_of_file(cmd)
  let utility#cmd_in_dir = 'cd ' . utility#directory_of_file() . ' && ' . a:cmd
  return substitute(utility#cmd_in_dir, "'", '"', 'g')
endfunction

function! utility#is_tracked_by_git()
  let cmd = utility#escape('git ls-files --error-unmatch' . utility#discard_stdout_and_stderr() . ' ' . shellescape(utility#file()))
  call system(utility#command_in_directory_of_file(cmd))
  return !v:shell_error
endfunction

function! utility#differences(hunks)
  return len(a:hunks) != 0
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
