" Vim doesn't namespace sign ids so every plugin shares the same
" namespace.  Sign ids are simply integers so to avoid clashes with other
" signs we guess at a clear run.
"
" Note also we currently never reset s:next_sign_id.
let s:first_sign_id = 3000
let s:next_sign_id  = s:first_sign_id
let s:dummy_sign_id = s:first_sign_id - 1


" Removes gitgutter's signs (excluding dummy sign) from the given file.
function! sign#clear_signs(file_name)
  call sign#find_current_signs(a:file_name)
  for sign in values(getbufvar(a:file_name, 'gitgutter_gitgutter_signs'))
    execute "sign unplace" sign.id
  endfor
  call setbufvar(a:file_name, 'gitgutter_gitgutter_signs', {})
endfunction


" Updates gitgutter's signs in the given file.
"
" modified_lines: list of [<line_number (number)>, <name (string)>]
" where name = 'added|removed|modified|modified_removed'
function! sign#update_signs(file_name, modified_lines)
  call sign#find_current_signs(a:file_name)

  let new_gitgutter_signs_line_numbers = map(copy(a:modified_lines), 'v:val[0]')
  let obsolete_signs = sign#obsolete_gitgutter_signs_to_remove(a:file_name, new_gitgutter_signs_line_numbers)

  let flicker_possible = s:remove_all_old_signs && !empty(a:modified_lines)
  if flicker_possible
    call sign#add_dummy_sign()
  endif

  call sign#remove_signs(obsolete_signs)
  call sign#upsert_new_gitgutter_signs(a:file_name, a:modified_lines)

  if flicker_possible
    call sign#remove_dummy_sign(0)
  endif
endfunction


function! sign#add_dummy_sign()
  if !getbufvar(utility#file(), 'gitgutter_dummy_sign')
    execute "sign place" s:dummy_sign_id "line=" . 9999 "name=GitGutterDummy file=" . utility#file()
    call setbufvar(utility#file(), 'gitgutter_dummy_sign', 1)
  endif
endfunction

function! sign#remove_dummy_sign(force)
  if getbufvar(utility#file(), 'gitgutter_dummy_sign') && (a:force || !g:gitgutter_sign_column_always)
    execute "sign unplace" s:dummy_sign_id "file=" . utility#file()
    call setbufvar(utility#file(), 'gitgutter_dummy_sign', 0)
  endif
endfunction


"
" Internal functions
"


function! sign#find_current_signs(file_name)
  let gitgutter_signs = {}  " <line_number (string)>: {'id': <id (number)>, 'name': <name (string)>}
  let other_signs = []      " [<line_number (number),...]
  let dummy_sign_placed = 0

  redir => signs
    silent execute "sign place file=" . a:file_name
  redir END

  for sign_line in filter(split(signs, '\n'), 'v:val =~# "="')
    " Typical sign line:  line=88 id=1234 name=GitGutterLineAdded
    " We assume splitting is faster than a regexp.
    let components  = split(sign_line)
    let name        = split(components[2], '=')[1]
    if name =~# 'GitGutterDummy'
      let dummy_sign_placed = 1
    else
      let line_number = str2nr(split(components[0], '=')[1])
      if name =~# 'GitGutter'
        let id = str2nr(split(components[1], '=')[1])
        " Remove orphaned signs (signs placed on lines which have been deleted).
        " (When a line is deleted its sign lingers.  Subsequent lines' signs'
        " line numbers are decremented appropriately.)
        if has_key(gitgutter_signs, line_number)
          execute "sign unplace" gitgutter_signs[line_number].id
        endif
        let gitgutter_signs[line_number] = {'id': id, 'name': name}
      else
        call add(other_signs, line_number)
      endif
    end
  endfor

  call setbufvar(a:file_name, 'gitgutter_dummy_sign', dummy_sign_placed)
  call setbufvar(a:file_name, 'gitgutter_gitgutter_signs', gitgutter_signs)
  call setbufvar(a:file_name, 'gitgutter_other_signs', other_signs)
endfunction


" Returns a list of [<id (number)>, ...]
function! sign#obsolete_gitgutter_signs_to_remove(file_name, new_gitgutter_signs_line_numbers)
  let signs_to_remove = []  " list of [<id (number)>, ...]
  let remove_all_signs = 1
  let old_gitgutter_signs = getbufvar(a:file_name, 'gitgutter_gitgutter_signs')
  for line_number in keys(old_gitgutter_signs)
    if index(a:new_gitgutter_signs_line_numbers, str2nr(line_number)) == -1
      call add(signs_to_remove, old_gitgutter_signs[line_number].id)
    else
      let remove_all_signs = 0
    endif
  endfor
  let s:remove_all_old_signs = remove_all_signs
  return signs_to_remove
endfunction

function! sign#remove_signs(sign_ids)
  for id in a:sign_ids
    execute "sign unplace" id
  endfor
endfunction


function! sign#upsert_new_gitgutter_signs(file_name, modified_lines)
  let other_signs         = getbufvar(a:file_name, 'gitgutter_other_signs')
  let old_gitgutter_signs = getbufvar(a:file_name, 'gitgutter_gitgutter_signs')

  for line in a:modified_lines
    let line_number = line[0]  " <number>
    if index(other_signs, line_number) == -1  " don't clobber others' signs
      let name = utility#highlight_name_for_change(line[1])
      if !has_key(old_gitgutter_signs, line_number)  " insert
        let id = sign#next_sign_id()
        execute "sign place" id "line=" . line_number "name=" . name "file=" . a:file_name
      else  " update if sign has changed
        let old_sign = old_gitgutter_signs[line_number]
        if old_sign.name !=# name
          execute "sign place" old_sign.id "name=" . name "file=" . a:file_name
        end
      endif
    endif
  endfor
  " At this point b:gitgutter_gitgutter_signs is out of date.
endfunction


function! sign#next_sign_id()
  let next_id = s:next_sign_id
  let s:next_sign_id += 1
  return next_id
endfunction
