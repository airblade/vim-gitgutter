" Vim doesn't namespace sign ids so every plugin shares the same
" namespace.  Sign ids are simply integers so to avoid clashes with other
" signs we guess at a clear run.
"
" Note also we currently never reset s:next_sign_id.
let s:first_sign_id = 3000
let s:next_sign_id = s:first_sign_id
let s:sign_ids = {}  " key: filename, value: list of sign ids
let s:other_signs = []
let s:dummy_sign_id = 153


function! sign#clear_signs(file_name)
  if exists('s:sign_ids') && has_key(s:sign_ids, a:file_name)
    for id in s:sign_ids[a:file_name]
      exe ":sign unplace" id "file=" . a:file_name
    endfor
    let s:sign_ids[a:file_name] = []
  endif
endfunction

" This assumes there are no GitGutter signs in the file.
" If this is untenable we could change the regexp to exclude GitGutter's
" signs.
function! sign#find_other_signs(file_name)
  redir => signs
    silent exe ":sign place file=" . a:file_name
  redir END
  let s:other_signs = []
  for sign_line in split(signs, '\n')
    if sign_line =~ '^\s\+\w\+='
      let matches = matchlist(sign_line, '^\s\+\w\+=\(\d\+\)')
      let line_number = str2nr(matches[1])
      call add(s:other_signs, line_number)
    endif
  endfor
endfunction

function! sign#show_signs(file_name, modified_lines)
  for line in a:modified_lines
    let line_number = line[0]
    let type = 'GitGutterLine' . utility#snake_case_to_camel_case(line[1])
    call sign#add_sign(line_number, type, a:file_name)
  endfor
endfunction

function! sign#add_sign(line_number, name, file_name)
  let id = sign#next_sign_id()
  if !sign#is_other_sign(a:line_number)  " Don't clobber other people's signs.
    exe ":sign place" id "line=" . a:line_number "name=" . a:name "file=" . a:file_name
    call sign#remember_sign(id, a:file_name)
  endif
endfunction

function! sign#next_sign_id()
  let next_id = s:next_sign_id
  let s:next_sign_id += 1
  return next_id
endfunction

function! sign#remember_sign(id, file_name)
  if has_key(s:sign_ids, a:file_name)
    let sign_ids_for_file = s:sign_ids[a:file_name]
    call add(sign_ids_for_file, a:id)
  else
    let sign_ids_for_file = [a:id]
  endif
  let s:sign_ids[a:file_name] = sign_ids_for_file
endfunction

function! sign#is_other_sign(line_number)
  return index(s:other_signs, a:line_number) == -1 ? 0 : 1
endfunction

function! sign#add_dummy_sign()
  let last_line = line('$')
  exe ":sign place" s:dummy_sign_id "line=" . (last_line + 1) "name=GitGutterDummy file=" . utility#file()
endfunction

function! sign#remove_dummy_sign()
  if exists('s:dummy_sign_id')
    exe ":sign unplace" s:dummy_sign_id "file=" . utility#file()
  endif
endfunction
