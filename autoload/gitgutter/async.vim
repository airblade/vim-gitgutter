let s:jobs = {}
" Async broken on MacVim in GUI mode:
" https://github.com/macvim-dev/macvim/issues/272
let s:available = has('nvim') || (has('patch-7-4-1826') && !(has('gui_macvim') && has('gui_running')))

function! gitgutter#async#available()
  return s:available
endfunction

function! gitgutter#async#execute(cmd)
  if has('nvim')
    let bufnr = gitgutter#utility#bufnr()
    let job_id = jobstart([&shell, &shellcmdflag, a:cmd], {
          \ 'buffer':    bufnr,
          \ 'on_stdout': function('gitgutter#async#handle_diff_job_nvim'),
          \ 'on_stderr': function('gitgutter#async#handle_diff_job_nvim'),
          \ 'on_exit':   function('gitgutter#async#handle_diff_job_nvim')
          \ })
    call gitgutter#debug#log('[nvim job: '.job_id.', buffer: '.bufnr.'] '.a:cmd)
    if job_id < 1
      throw 'diff failed'
    endif

    " Note that when `cmd` doesn't produce any output, i.e. the diff is empty,
    " the `stdout` event is not fired on the job handler.  Therefore we keep
    " track of the jobs ourselves so we can spot empty diffs.
    call s:job_started(job_id)

  else
    " Pass a handler for stdout but not for stderr so that errors are
    " ignored (and thus signs are not updated; this assumes that an error
    " only occurs when a file is not tracked by git).
    let job = job_start([&shell, &shellcmdflag, a:cmd], {
          \ 'out_cb':   'gitgutter#async#handle_diff_job_vim',
          \ 'close_cb': 'gitgutter#async#handle_diff_job_vim_close'
          \ })
    call gitgutter#debug#log('[vim job: '.string(job_info(job)).'] '.a:cmd)
  endif
endfunction


function! gitgutter#async#handle_diff_job_nvim(job_id, data, event)
  call gitgutter#debug#log('job_id: '.a:job_id.', event: '.a:event.', buffer: '.self.buffer)

  let current_buffer = gitgutter#utility#bufnr()
  call gitgutter#utility#set_buffer(self.buffer)

  if a:event == 'stdout'
    " a:data is a list
    call s:job_finished(a:job_id)
    call gitgutter#handle_diff(gitgutter#utility#stringify(a:data))

  elseif a:event == 'exit'
    " If the exit event is triggered without a preceding stdout event,
    " the diff was empty.
    if s:is_job_started(a:job_id)
      call gitgutter#handle_diff("")
      call s:job_finished(a:job_id)
    endif

  else  " a:event is stderr
    call gitgutter#hunk#reset()
    call s:job_finished(a:job_id)

  endif

  call gitgutter#utility#set_buffer(current_buffer)
endfunction


" Channel is in NL mode.
function! gitgutter#async#handle_diff_job_vim(channel, line)
  call gitgutter#debug#log('channel: '.a:channel.', line: '.a:line)

  " This seems to be the only way to get info about the channel once closed.
  let channel_id = matchstr(a:channel, '\d\+')

  call s:accumulate_job_output(channel_id, a:line)
endfunction

function! gitgutter#async#handle_diff_job_vim_close(channel)
  call gitgutter#debug#log('channel: '.a:channel)

  " This seems to be the only way to get info about the channel once closed.
  let channel_id = matchstr(a:channel, '\d\+')

  call gitgutter#handle_diff(s:job_output(channel_id))
  call s:job_finished(channel_id)
endfunction


function! s:job_started(id)
  let s:jobs[a:id] = 1
endfunction

function! s:is_job_started(id)
  return has_key(s:jobs, a:id)
endfunction

function! s:accumulate_job_output(id, line)
  if has_key(s:jobs, a:id)
    let s:jobs[a:id] = add(s:jobs[a:id], a:line)
  else
    let s:jobs[a:id] = [a:line]
  endif
endfunction

" Returns a string
function! s:job_output(id)
  if has_key(s:jobs, a:id)
    return gitgutter#utility#stringify(s:jobs[a:id])
  else
    return ""
  endif
endfunction

function! s:job_finished(id)
  if has_key(s:jobs, a:id)
    unlet s:jobs[a:id]
  endif
endfunction
