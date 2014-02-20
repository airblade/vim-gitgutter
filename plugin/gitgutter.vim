if exists('g:loaded_gitgutter') || !executable('git') || !has('signs') || &cp
  finish
endif
let g:loaded_gitgutter = 1

" Initialisation {{{

" Realtime sign updates require Vim 7.3.105+.
if v:version < 703 || (v:version == 703 && !has("patch105"))
  let g:gitgutter_realtime = 0
endif

function! s:set(var, default)
  if !exists(a:var)
    if type(a:default)
      execute 'let' a:var '=' string(a:default)
    else
      execute 'let' a:var '=' a:default
    endif
  endif
endfunction

call s:set('g:gitgutter_enabled',               1)
call s:set('g:gitgutter_signs',                 1)
call s:set('g:gitgutter_highlight_lines',       0)
call s:set('g:gitgutter_sign_column_always',    0)
call s:set('g:gitgutter_realtime',              1)
call s:set('g:gitgutter_eager',                 1)
call s:set('g:gitgutter_sign_added',            '+')
call s:set('g:gitgutter_sign_modified',         '~')
call s:set('g:gitgutter_sign_removed',          '_')
call s:set('g:gitgutter_sign_modified_removed', '~_')
call s:set('g:gitgutter_diff_args',             '')
call s:set('g:gitgutter_escape_grep',           0)
call s:set('g:gitgutter_map_keys',              1)

call highlight#define_sign_column_highlight()
call highlight#define_highlights()
call highlight#define_signs()

" }}}


" Primary functions {{{

function! GitGutterAll()
  for buffer_id in tabpagebuflist()
    let file = expand('#' . buffer_id . ':p')
    if !empty(file)
      call GitGutter(file, 0)
    endif
  endfor
endfunction
command GitGutterAll call GitGutterAll()

" Does the actual work.
"
" file: (string) the file to process.
" realtime: (boolean) when truthy, do a realtime diff; otherwise do a disk-based diff.
function! GitGutter(file, realtime)
  call utility#set_file(a:file)
  if utility#is_active()
    if g:gitgutter_sign_column_always
      call sign#add_dummy_sign()
    endif
    try
      if !a:realtime || utility#has_fresh_changes(a:file)
        let diff           = diff#run_diff(a:realtime || utility#has_unsaved_changes(a:file), 1)
        let s:hunks        = diff#parse_diff(diff)
        let modified_lines = diff#process_hunks(s:hunks)

        if g:gitgutter_signs
          call sign#update_signs(a:file, modified_lines)
        endif

        call utility#save_last_seen_change(a:file)
      endif
    catch /diff failed/
      call hunk#reset()
    endtry
  else
    call hunk#reset()
  endif
endfunction
command GitGutter call GitGutter(utility#current_file(), 0)

" }}}


" The plugin: enable / disable / toggle {{{

function! GitGutterDisable()
  let g:gitgutter_enabled = 0
  call sign#clear_signs(utility#file())
  call sign#remove_dummy_sign(1)
  call hunk#reset()
endfunction
command GitGutterDisable call GitGutterDisable()

function! GitGutterEnable()
  let g:gitgutter_enabled = 1
  call GitGutter(utility#current_file(), 0)
endfunction
command GitGutterEnable call GitGutterEnable()

function! GitGutterToggle()
  if g:gitgutter_enabled
    call GitGutterDisable()
  else
    call GitGutterEnable()
  endif
endfunction
command GitGutterToggle call GitGutterToggle()

" }}}


" Line highlights: enable / disable / toggle {{{

function! GitGutterLineHighlightsDisable()
  let g:gitgutter_highlight_lines = 0
  call highlight#define_sign_line_highlights()
  redraw!
endfunction
command GitGutterLineHighlightsDisable call GitGutterLineHighlightsDisable()

function! GitGutterLineHighlightsEnable()
  let g:gitgutter_highlight_lines = 1
  call highlight#define_sign_line_highlights()
  redraw!
endfunction
command GitGutterLineHighlightsEnable call GitGutterLineHighlightsEnable()

function! GitGutterLineHighlightsToggle()
  let g:gitgutter_highlight_lines = !g:gitgutter_highlight_lines
  call highlight#define_sign_line_highlights()
  redraw!
endfunction
command GitGutterLineHighlightsToggle call GitGutterLineHighlightsToggle()

" }}}


" Signs: enable / disable / toggle {{{

function! GitGutterSignsEnable()
  let g:gitgutter_signs = 1
  call GitGutterAll()
endfunction
command GitGutterSignsEnable call GitGutterSignsEnable()

function! GitGutterSignsDisable()
  let g:gitgutter_signs = 0
  call sign#clear_signs(utility#file())
  call sign#remove_dummy_sign(0)
endfunction
command GitGutterSignsDisable call GitGutterSignsDisable()

function! GitGutterSignsToggle()
  if g:gitgutter_signs
    call GitGutterSignsDisable()
  else
    call GitGutterSignsEnable()
  endif
endfunction
command GitGutterSignsToggle call GitGutterSignsToggle()

" }}}


" Hunks: jump to next/previous {{{

function! GitGutterNextHunk(count)
  if utility#is_active()
    let current_line = line('.')
    let hunk_count = 0
    for hunk in s:hunks
      if hunk[2] > current_line
        let hunk_count += 1
        if hunk_count == a:count
          execute 'normal!' hunk[2] . 'G'
          break
        endif
      endif
    endfor
  endif
endfunction
command -count=1 GitGutterNextHunk call GitGutterNextHunk(<count>)

function! GitGutterPrevHunk(count)
  if utility#is_active()
    let current_line = line('.')
    let hunk_count = 0
    for hunk in reverse(copy(s:hunks))
      if hunk[2] < current_line
        let hunk_count += 1
        if hunk_count == a:count
          execute 'normal!' hunk[2] . 'G'
          break
        endif
      endif
    endfor
  endif
endfunction
command -count=1 GitGutterPrevHunk call GitGutterPrevHunk(<count>)

" }}}


" Hunks: stage/revert {{{

function! GitGutterStageHunk()
  if utility#is_active()
    " Ensure the working copy of the file is up to date.
    " It doesn't make sense to stage a hunk otherwise.
    silent write

    " find current hunk (i.e. which one the cursor is in)
    let current_hunk = []
    let current_line = line('.')
    for hunk in s:hunks
      if current_line >= hunk[2] && current_line < hunk[2] + (hunk[3] == 0 ? 1 : hunk[3])
        let current_hunk = hunk
        break
      endif
    endfor
    if len(current_hunk) != 4
      return
    endif

    " construct a diff
    let diff_for_hunk = diff#generate_diff_for_hunk(current_hunk)

    " apply the diff
    call system(utility#command_in_directory_of_file('git apply --cached --unidiff-zero - '), diff_for_hunk)

    " refresh gitgutter's view of buffer
    silent execute "GitGutter"
  endif
endfunction
command GitGutterStageHunk call GitGutterStageHunk()

function! GitGutterRevertHunk()
  if utility#is_active()
    " Ensure the working copy of the file is up to date.
    " It doesn't make sense to stage a hunk otherwise.
    write

    " find current hunk (i.e. which one the cursor is in)
    let current_hunk = []
    let current_line = line('.')
    for hunk in s:hunks
      if current_line >= hunk[2] && current_line < hunk[2] + (hunk[3] == 0 ? 1 : hunk[3])
        let current_hunk = hunk
        break
      endif
    endfor
    if len(current_hunk) != 4
      return
    endif

    " construct a diff
    let diff_for_hunk = diff#generate_diff_for_hunk(current_hunk)

    " apply the diff
    call system(utility#command_in_directory_of_file('git apply --reverse --unidiff-zero - '), diff_for_hunk)

    " reload file
    silent edit
  endif
endfunction
command GitGutterRevertHunk call GitGutterRevertHunk()

" }}}


" Hunk stats {{{

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
  return utility#is_active() ? s:hunks : []
endfunction

" Returns an array that contains a summary of the current hunk status.
" The format is [ added, modified, removed ], where each value represents
" the number of lines added/modified/removed respectively.
function! GitGutterGetHunkSummary()
  return hunk#summary()
endfunction

" }}}

command GitGutterDebug call debug#debug()

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


nnoremap <silent> <Plug>GitGutterStageHunk :GitGutterStageHunk<CR>
nnoremap <silent> <Plug>GitGutterRevertHunk :GitGutterRevertHunk<CR>

if g:gitgutter_map_keys
  if !hasmapto('<Plug>GitGutterStageHunk') && maparg('<Leader>hs', 'n') ==# ''
    nmap <Leader>hs <Plug>GitGutterStageHunk
  endif
  if !hasmapto('<Plug>GitGutterRevertHunk') && maparg('<Leader>hr', 'n') ==# ''
    nmap <Leader>hr <Plug>GitGutterRevertHunk
  endif
endif

" }}}


" Autocommands {{{

augroup gitgutter
  autocmd!

  if g:gitgutter_realtime
    autocmd CursorHold,CursorHoldI * call GitGutter(utility#current_file(), 1)
  endif

  if g:gitgutter_eager
    autocmd BufEnter,BufWritePost,FileChangedShellPost *
          \  if gettabvar(tabpagenr(), 'gitgutter_didtabenter')
          \|   call settabvar(tabpagenr(), 'gitgutter_didtabenter', 0)
          \| else
          \|   call GitGutter(utility#current_file(), 0)
          \| endif
    autocmd TabEnter *
          \  call settabvar(tabpagenr(), 'gitgutter_didtabenter', 1)
          \| call GitGutterAll()
    if !has('gui_win32')
      autocmd FocusGained * call GitGutterAll()
    endif
  else
    autocmd BufRead,BufWritePost,FileChangedShellPost * call GitGutter(utility#current_file(), 0)
  endif

  autocmd ColorScheme * call highlight#define_sign_column_highlight() | call highlight#define_highlights()

  " Disable during :vimgrep
  autocmd QuickFixCmdPre  *vimgrep* let g:gitgutter_enabled = 0
  autocmd QuickFixCmdPost *vimgrep* let g:gitgutter_enabled = 1
augroup END

" }}}


" vim:set et sw=2 fdm=marker:
