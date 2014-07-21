let s:file = ''
let s:using_xolox_shell = -1
let s:exit_code = 0

function! gitgutter#utility#warn(message)
  echohl WarningMsg
  echomsg 'vim-gitgutter: ' . a:message
  echohl None
  let b:warningmsg = a:message
endfunction

function! gitgutter#utility#is_active()
  return g:gitgutter_enabled && gitgutter#utility#exists_file()
endfunction

" A replacement for the built-in `shellescape(arg)`.
"
" Recent versions of Vim handle shell escaping pretty well.  However older
" versions aren't as good.  This attempts to do the right thing.
"
" See:
" https://github.com/tpope/vim-fugitive/blob/8f0b8edfbd246c0026b7a2388e1d883d579ac7f6/plugin/fugitive.vim#L29-L37
function! gitgutter#utility#shellescape(arg)
  if a:arg =~ '^[A-Za-z0-9_/.-]\+$'
    return a:arg
  elseif &shell =~# 'cmd' || gitgutter#utility#using_xolox_shell()
    return '"' . substitute(substitute(a:arg, '"', '""', 'g'), '%', '"%"', 'g') . '"'
  else
    return shellescape(a:arg)
  endif
endfunction

function! gitgutter#utility#current_file()
  return expand('%:p')
endfunction

function! gitgutter#utility#set_file(file)
  let s:file = a:file
endfunction

function! gitgutter#utility#file()
  return s:file
endfunction

function! gitgutter#utility#filename()
  return fnamemodify(s:file, ':t')
endfunction

function! gitgutter#utility#directory_of_file()
  return fnamemodify(s:file, ':h')
endfunction

function! gitgutter#utility#exists_file()
  return filereadable(gitgutter#utility#file())
endfunction

function! gitgutter#utility#has_unsaved_changes(file)
  return getbufvar(a:file, "&mod")
endfunction

function! gitgutter#utility#has_fresh_changes(file)
  return getbufvar(a:file, 'changedtick') != getbufvar(a:file, 'gitgutter_last_tick')
endfunction

function! gitgutter#utility#save_last_seen_change(file)
  call setbufvar(a:file, 'gitgutter_last_tick', getbufvar(a:file, 'changedtick'))
endfunction

function! gitgutter#utility#buffer_contents()
  if &fileformat ==# "dos"
    let eol = "\r\n"
  elseif &fileformat ==# "mac"
    let eol = "\r"
  else
    let eol = "\n"
  endif
  return join(getbufline(s:file, 1, '$'), eol) . eol
endfunction

function! gitgutter#utility#shell_error()
  return gitgutter#utility#using_xolox_shell() ? s:exit_code : v:shell_error
endfunction

function! gitgutter#utility#using_xolox_shell()
  if s:using_xolox_shell == -1
    if !g:gitgutter_avoid_cmd_prompt_on_windows
      let s:using_xolox_shell = 0
    " Although xolox/vim-shell works on both windows and unix we only want to use
    " it on windows.
    elseif has('win32') || has('win64') || has('win32unix')
      let s:using_xolox_shell = exists('g:xolox#misc#version') && exists('g:xolox#shell#version')
    else
      let s:using_xolox_shell = 0
    endif
  endif
  return s:using_xolox_shell
endfunction

function! gitgutter#utility#system(cmd, ...)
  if gitgutter#utility#using_xolox_shell()
    let options = {'command': a:cmd, 'check': 0}
    if a:0 > 0
      let options['stdin'] = a:1
    endif
    let ret = xolox#misc#os#exec(options)
    let output = join(ret.stdout, "\n")
    let s:exit_code = ret.exit_code
  else
    let output = (a:0 == 0) ? system(a:cmd) : system(a:cmd, a:1)
  endif
  return output
endfunction

function! gitgutter#utility#file_relative_to_repo_root()
  let file_path_relative_to_repo_root = getbufvar(s:file, 'gitgutter_repo_relative_path')
  if empty(file_path_relative_to_repo_root)
    let dir_path_relative_to_repo_root = gitgutter#utility#system(gitgutter#utility#command_in_directory_of_file('git rev-parse --show-prefix'))
    let dir_path_relative_to_repo_root = gitgutter#utility#strip_trailing_new_line(dir_path_relative_to_repo_root)
    let file_path_relative_to_repo_root = dir_path_relative_to_repo_root . gitgutter#utility#filename()
    call setbufvar(s:file, 'gitgutter_repo_relative_path', file_path_relative_to_repo_root)
  endif
  return file_path_relative_to_repo_root
endfunction

function! gitgutter#utility#command_in_directory_of_file(cmd)
  return 'cd ' . gitgutter#utility#shellescape(gitgutter#utility#directory_of_file()) . ' && ' . a:cmd
endfunction

function! gitgutter#utility#highlight_name_for_change(text)
  if a:text ==# 'added'
    return 'GitGutterLineAdded'
  elseif a:text ==# 'removed'
    return 'GitGutterLineRemoved'
  elseif a:text ==# 'removed_first_line'
    return 'GitGutterLineRemovedFirstLine'
  elseif a:text ==# 'modified'
    return 'GitGutterLineModified'
  elseif a:text ==# 'modified_removed'
    return 'GitGutterLineModifiedRemoved'
  endif
endfunction

function! gitgutter#utility#strip_trailing_new_line(line)
  return substitute(a:line, '\n$', '', '')
endfunction
