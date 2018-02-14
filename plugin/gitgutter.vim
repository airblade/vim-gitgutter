scriptencoding utf-8

if exists('g:loaded_gitgutter') || !has('signs') || &cp
  finish
endif
let g:loaded_gitgutter = 1

" Initialisation {{{

" Realtime sign updates require Vim 7.3.105+.
if v:version < 703 || (v:version == 703 && !has("patch105"))
  let g:gitgutter_realtime = 0
endif

" Eager updates require gettabvar()/settabvar().
if !exists("*gettabvar")
  let g:gitgutter_eager = 0
endif

function! s:set(var, default) abort
  if !exists(a:var)
    if type(a:default)
      execute 'let' a:var '=' string(a:default)
    else
      execute 'let' a:var '=' a:default
    endif
  endif
endfunction

call s:set('g:gitgutter_enabled',                     1)
call s:set('g:gitgutter_max_signs',                 500)
call s:set('g:gitgutter_signs',                       1)
call s:set('g:gitgutter_highlight_lines',             0)
call s:set('g:gitgutter_sign_column_always',          0)
if g:gitgutter_sign_column_always && exists('&signcolumn')
  " Vim 7.4.2201.
  set signcolumn=yes
  let g:gitgutter_sign_column_always = 0
  call gitgutter#utility#warn('please replace "let g:gitgutter_sign_column_always=1" with "set signcolumn=yes"')
endif
call s:set('g:gitgutter_override_sign_column_highlight', 1)
call s:set('g:gitgutter_sign_added',                '+')
call s:set('g:gitgutter_sign_modified',             '~')
call s:set('g:gitgutter_sign_removed',              '_')
if has("gui_running") || &termencoding == "utf-8"
  call s:set('g:gitgutter_sign_removed_first_line', '‾')
else
  call s:set('g:gitgutter_sign_removed_first_line', '_^')
endif

call s:set('g:gitgutter_sign_modified_removed',    '~_')
call s:set('g:gitgutter_diff_args',                  '')
call s:set('g:gitgutter_diff_base',                  '')
call s:set('g:gitgutter_map_keys',                    1)
call s:set('g:gitgutter_async',                       1)
call s:set('g:gitgutter_log',                         0)

call s:set('g:gitgutter_git_executable', 'git')
if !executable(g:gitgutter_git_executable)
  call gitgutter#utility#warn('cannot find git. Please set g:gitgutter_git_executable.')
endif

call s:set('g:gitgutter_grep', 'grep')
if !empty(g:gitgutter_grep)
  if !executable(g:gitgutter_grep)
    call gitgutter#utility#warn('cannot find '.g:gitgutter_grep.'. Please set g:gitgutter_grep.')
    let g:gitgutter_grep = ''
  else
    if $GREP_OPTIONS =~# '--color=always'
      let g:gitgutter_grep .= ' --color=never'
    endif
  endif
endif

call gitgutter#highlight#define_sign_column_highlight()
call gitgutter#highlight#define_highlights()
call gitgutter#highlight#define_signs()

" }}}

" Primary functions {{{

command -bar GitGutterAll call gitgutter#all(1)
command -bar GitGutter    call gitgutter#process_buffer(bufnr(''), 1)

command -bar GitGutterDisable call gitgutter#disable()
command -bar GitGutterEnable  call gitgutter#enable()
command -bar GitGutterToggle  call gitgutter#toggle()

" }}}

" Line highlights {{{

command -bar GitGutterLineHighlightsDisable call gitgutter#highlight#line_disable()
command -bar GitGutterLineHighlightsEnable  call gitgutter#highlight#line_enable()
command -bar GitGutterLineHighlightsToggle  call gitgutter#highlight#line_toggle()

" }}}

" Signs {{{

command -bar GitGutterSignsEnable  call gitgutter#sign#enable()
command -bar GitGutterSignsDisable call gitgutter#sign#disable()
command -bar GitGutterSignsToggle  call gitgutter#sign#toggle()

" }}}

" Hunks {{{

command -bar -count=1 GitGutterNextHunk call gitgutter#hunk#next_hunk(<count>)
command -bar -count=1 GitGutterPrevHunk call gitgutter#hunk#prev_hunk(<count>)

command -bar GitGutterStageHunk   call gitgutter#hunk#stage()
command -bar GitGutterUndoHunk    call gitgutter#hunk#undo()
command -bar GitGutterRevertHunk  echomsg 'GitGutterRevertHunk is deprecated. Use GitGutterUndoHunk'<Bar>call gitgutter#hunk#undo()
command -bar GitGutterPreviewHunk call gitgutter#hunk#preview()

" Hunk text object
onoremap <silent> <Plug>GitGutterTextObjectInnerPending :<C-U>call gitgutter#hunk#text_object(1)<CR>
onoremap <silent> <Plug>GitGutterTextObjectOuterPending :<C-U>call gitgutter#hunk#text_object(0)<CR>
xnoremap <silent> <Plug>GitGutterTextObjectInnerVisual  :<C-U>call gitgutter#hunk#text_object(1)<CR>
xnoremap <silent> <Plug>GitGutterTextObjectOuterVisual  :<C-U>call gitgutter#hunk#text_object(0)<CR>


" Returns the git-diff hunks for the file or an empty list if there
" aren't any hunks.
"
" The return value is a list of lists.  There is one inner list per hunk.
"
"   [
"     [from_line, from_count, to_line, to_count],
"     [from_line, from_count, to_line, to_count],
"     ...
"   ]
"
" where:
"
" `from`  - refers to the staged file
" `to`    - refers to the working tree's file
" `line`  - refers to the line number where the change starts
" `count` - refers to the number of lines the change covers
function! GitGutterGetHunks()
  let bufnr = bufnr('')
  return gitgutter#utility#is_active(bufnr) ? gitgutter#hunk#hunks(bufnr) : []
endfunction

" Returns an array that contains a summary of the hunk status for the current
" window.  The format is [ added, modified, removed ], where each value
" represents the number of lines added/modified/removed respectively.
function! GitGutterGetHunkSummary()
  return gitgutter#hunk#summary(winbufnr(0))
endfunction

" }}}

command -bar GitGutterDebug call gitgutter#debug#debug()

" Maps {{{

nnoremap <silent> <expr> <Plug>GitGutterNextHunk &diff ? ']c' : ":\<C-U>execute v:count1 . 'GitGutterNextHunk'\<CR>"
nnoremap <silent> <expr> <Plug>GitGutterPrevHunk &diff ? '[c' : ":\<C-U>execute v:count1 . 'GitGutterPrevHunk'\<CR>"

if g:gitgutter_map_keys
  if !hasmapto('<Plug>GitGutterPrevHunk') && maparg('[c', 'n') ==# ''
    nmap [c <Plug>GitGutterPrevHunk
  endif
  if !hasmapto('<Plug>GitGutterNextHunk') && maparg(']c', 'n') ==# ''
    nmap ]c <Plug>GitGutterNextHunk
  endif
endif


nnoremap <silent> <Plug>GitGutterStageHunk   :GitGutterStageHunk<CR>
nnoremap <silent> <Plug>GitGutterUndoHunk    :GitGutterUndoHunk<CR>
nnoremap <silent> <Plug>GitGutterPreviewHunk :GitGutterPreviewHunk<CR>

if g:gitgutter_map_keys
  if !hasmapto('<Plug>GitGutterStageHunk') && maparg('<Leader>hs', 'n') ==# ''
    nmap <Leader>hs <Plug>GitGutterStageHunk
  endif
  if !hasmapto('<Plug>GitGutterUndoHunk') && maparg('<Leader>hu', 'n') ==# ''
    nmap <Leader>hu <Plug>GitGutterUndoHunk
  endif
  if !hasmapto('<Plug>GitGutterPreviewHunk') && maparg('<Leader>hp', 'n') ==# ''
    nmap <Leader>hp <Plug>GitGutterPreviewHunk
  endif

  if !hasmapto('<Plug>GitGutterTextObjectInnerPending') && maparg('ic', 'o') ==# ''
    omap ic <Plug>GitGutterTextObjectInnerPending
  endif
  if !hasmapto('<Plug>GitGutterTextObjectOuterPending') && maparg('ac', 'o') ==# ''
    omap ac <Plug>GitGutterTextObjectOuterPending
  endif
  if !hasmapto('<Plug>GitGutterTextObjectInnerVisual') && maparg('ic', 'x') ==# ''
    xmap ic <Plug>GitGutterTextObjectInnerVisual
  endif
  if !hasmapto('<Plug>GitGutterTextObjectOuterVisual') && maparg('ac', 'x') ==# ''
    xmap ac <Plug>GitGutterTextObjectOuterVisual
  endif
endif

" }}}

" Autocommands {{{

augroup gitgutter
  autocmd!

  autocmd TabEnter * call settabvar(tabpagenr(), 'gitgutter_didtabenter', 1)

  autocmd BufEnter *
        \ if gettabvar(tabpagenr(), 'gitgutter_didtabenter') |
        \   call settabvar(tabpagenr(), 'gitgutter_didtabenter', 0) |
        \   call gitgutter#all(0) |
        \ else |
        \   call gitgutter#init_buffer(bufnr('')) |
        \   call gitgutter#process_buffer(bufnr(''), 0) |
        \ endif

  autocmd CursorHold,CursorHoldI            * call gitgutter#process_buffer(bufnr(''), 0)
  autocmd FileChangedShellPost,ShellCmdPost * call gitgutter#process_buffer(bufnr(''), 1)

  " Ensure that all buffers are processed when opening vim with multiple files, e.g.:
  "
  "   vim -o file1 file2
  autocmd VimEnter * if winnr() != winnr('$') | call gitgutter#all(0) | endif

  if !has('gui_win32')
    autocmd FocusGained * call gitgutter#all(1)
  endif

  autocmd ColorScheme * call gitgutter#highlight#define_sign_column_highlight() | call gitgutter#highlight#define_highlights()

  " Disable during :vimgrep
  autocmd QuickFixCmdPre  *vimgrep* let g:gitgutter_enabled = 0
  autocmd QuickFixCmdPost *vimgrep* let g:gitgutter_enabled = 1
augroup END

" }}}

" vim:set et sw=2 fdm=marker:
