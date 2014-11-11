" Vim doesn't namespace sign ids so every plugin shares the same
" namespace.  Sign ids are simply integers so to avoid clashes with other
" signs we guess at a clear run.
"
" Note also we currently never reset s:next_sign_id.
let s:first_sign_id = 3000
let s:next_sign_id  = s:first_sign_id
let s:dummy_sign_id = s:first_sign_id - 1
" Remove-all-signs optimisation requires Vim 7.3.596+.
let s:supports_star = v:version > 703 || (v:version == 703 && has("patch596"))


" Removes gitgutter's signs (excluding dummy sign) from the given file.
function! gitgutter#sign#clear_signs(buf)
  call gitgutter#sign#find_current_signs(a:buf)

  let sign_ids = map(values(getbufvar(a:buf, 'gitgutter_gitgutter_signs')), 'v:val.id')
  call gitgutter#sign#remove_signs(sign_ids, a:buf, 1)
  call setbufvar(a:buf, 'gitgutter_gitgutter_signs', {})
endfunction


" Updates gitgutter's signs in the given file.
"
" modified_lines: list of [<line_number (number)>, <name (string)>]
" where name = 'added|removed|modified|modified_removed'
function! gitgutter#sign#update_signs(buf, modified_lines)
  call gitgutter#sign#find_current_signs(a:buf)

  let new_gitgutter_signs_line_numbers = map(copy(a:modified_lines), 'v:val[0]')
  let obsolete_signs = gitgutter#sign#obsolete_gitgutter_signs_to_remove(a:buf, new_gitgutter_signs_line_numbers)

  let flicker_possible = s:remove_all_old_signs && !empty(a:modified_lines)
  if flicker_possible
    call gitgutter#sign#add_dummy_sign()
  endif

  call gitgutter#sign#remove_signs(obsolete_signs, a:buf, s:remove_all_old_signs)
  call gitgutter#sign#upsert_new_gitgutter_signs(a:buf, a:modified_lines)

  if flicker_possible
    call gitgutter#sign#remove_dummy_sign(0)
  endif
endfunction


function! gitgutter#sign#add_dummy_sign()
  if !getbufvar(gitgutter#utility#buf(), 'gitgutter_dummy_sign')
    execute "sign place" s:dummy_sign_id "line=" . 9999 "name=GitGutterDummy buffer=" . gitgutter#utility#buf()
    call setbufvar(gitgutter#utility#buf(), 'gitgutter_dummy_sign', 1)
  endif
endfunction

function! gitgutter#sign#remove_dummy_sign(force)
  if getbufvar(gitgutter#utility#buf(), 'gitgutter_dummy_sign') && (a:force || !g:gitgutter_sign_column_always)
    execute "sign unplace" s:dummy_sign_id "buffer=" . gitgutter#utility#buf()
    call setbufvar(gitgutter#utility#buf(), 'gitgutter_dummy_sign', 0)
  endif
endfunction


"
" Internal functions
"


function! gitgutter#sign#find_current_signs(buf)
  let gitgutter_signs = {}  " <line_number (string)>: {'id': <id (number)>, 'name': <name (string)>}
  let other_signs = []      " [<line_number (number),...]
  let dummy_sign_placed = 0

  redir => signs
    silent execute "sign place buffer=" . a:buf
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

  call setbufvar(a:buf, 'gitgutter_dummy_sign', dummy_sign_placed)
  call setbufvar(a:buf, 'gitgutter_gitgutter_signs', gitgutter_signs)
  call setbufvar(a:buf, 'gitgutter_other_signs', other_signs)
endfunction


" Returns a list of [<id (number)>, ...]
" Sets `s:remove_all_old_signs` as a side-effect.
function! gitgutter#sign#obsolete_gitgutter_signs_to_remove(buf, new_gitgutter_signs_line_numbers)
  let signs_to_remove = []  " list of [<id (number)>, ...]
  let remove_all_signs = 1
  let old_gitgutter_signs = getbufvar(a:buf, 'gitgutter_gitgutter_signs')
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


function! gitgutter#sign#remove_signs(sign_ids, buf, all_signs)
  if a:all_signs && s:supports_star && empty(getbufvar(a:buf, 'gitgutter_other_signs'))
    let dummy_sign_present = getbufvar(a:buf, 'gitgutter_dummy_sign')
    execute "sign unplace * buffer=" . a:buf
    if dummy_sign_present
      execute "sign place" s:dummy_sign_id "line=" . 9999 "name=GitGutterDummy buffer=" . a:buf
    endif
  else
    for id in a:sign_ids
      execute "sign unplace" id
    endfor
  endif
endfunction


function! gitgutter#sign#upsert_new_gitgutter_signs(buf, modified_lines)
  let other_signs         = getbufvar(a:buf, 'gitgutter_other_signs')
  let old_gitgutter_signs = getbufvar(a:buf, 'gitgutter_gitgutter_signs')

  for line in a:modified_lines
    let line_number = line[0]  " <number>
    if index(other_signs, line_number) == -1  " don't clobber others' signs
      let name = gitgutter#utility#highlight_name_for_change(line[1])
      if !has_key(old_gitgutter_signs, line_number)  " insert
        let id = gitgutter#sign#next_sign_id()
        execute "sign place" id "line=" . line_number "name=" . name "buffer=" . a:buf
      else  " update if sign has changed
        let old_sign = old_gitgutter_signs[line_number]
        if old_sign.name !=# name
          execute "sign place" old_sign.id "name=" . name "buffer=" . a:buf
        end
      endif
    endif
  endfor
  " At this point b:gitgutter_gitgutter_signs is out of date.
endfunction


function! gitgutter#sign#next_sign_id()
  let next_id = s:next_sign_id
  let s:next_sign_id += 1
  return next_id
endfunction
