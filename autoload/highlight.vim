function! highlight#define_sign_column_highlight()
  highlight default link SignColumn LineNr
endfunction

function! highlight#define_highlights()
  let [guibg, ctermbg] = highlight#get_background_colors('SignColumn')

  " Highlights used by the signs.
  execute "highlight GitGutterAddDefault    guifg=#009900 guibg=" . guibg . " ctermfg=2 ctermbg=" . ctermbg
  execute "highlight GitGutterChangeDefault guifg=#bbbb00 guibg=" . guibg . " ctermfg=3 ctermbg=" . ctermbg
  execute "highlight GitGutterDeleteDefault guifg=#ff2222 guibg=" . guibg . " ctermfg=1 ctermbg=" . ctermbg
  highlight default link GitGutterChangeDeleteDefault GitGutterChangeDefault

  highlight default link GitGutterAdd          GitGutterAddDefault
  highlight default link GitGutterChange       GitGutterChangeDefault
  highlight default link GitGutterDelete       GitGutterDeleteDefault
  highlight default link GitGutterChangeDelete GitGutterChangeDeleteDefault

  " Highlights used for the whole line.
  highlight default link GitGutterAddLine          DiffAdd
  highlight default link GitGutterChangeLine       DiffChange
  highlight default link GitGutterDeleteLine       DiffDelete
  highlight default link GitGutterChangeDeleteLine GitGutterChangeLineDefault
endfunction

function! highlight#define_signs()
  sign define GitGutterLineAdded
  sign define GitGutterLineModified
  sign define GitGutterLineRemoved
  sign define GitGutterLineModifiedRemoved
  sign define GitGutterDummy

  call highlight#define_sign_symbols()
  call highlight#define_sign_text_highlights()
  call highlight#define_sign_line_highlights()
endfunction

function! highlight#define_sign_symbols()
  execute "sign define GitGutterLineAdded           text=" . g:gitgutter_sign_added
  execute "sign define GitGutterLineModified        text=" . g:gitgutter_sign_modified
  execute "sign define GitGutterLineRemoved         text=" . g:gitgutter_sign_removed
  execute "sign define GitGutterLineModifiedRemoved text=" . g:gitgutter_sign_modified_removed
endfunction

function! highlight#define_sign_text_highlights()
  sign define GitGutterLineAdded           texthl=GitGutterAdd
  sign define GitGutterLineModified        texthl=GitGutterChange
  sign define GitGutterLineRemoved         texthl=GitGutterDelete
  sign define GitGutterLineModifiedRemoved texthl=GitGutterChangeDelete
endfunction

function! highlight#define_sign_line_highlights()
  if g:gitgutter_highlight_lines
    sign define GitGutterLineAdded           linehl=GitGutterAddLine
    sign define GitGutterLineModified        linehl=GitGutterChangeLine
    sign define GitGutterLineRemoved         linehl=GitGutterDeleteLine
    sign define GitGutterLineModifiedRemoved linehl=GitGutterChangeDeleteLine
  else
    sign define GitGutterLineAdded           linehl=
    sign define GitGutterLineModified        linehl=
    sign define GitGutterLineRemoved         linehl=
    sign define GitGutterLineModifiedRemoved linehl=
  endif
endfunction

function! highlight#get_background_colors(group)
  redir => highlight
  silent execute 'silent highlight ' . a:group
  redir END

  let link_matches = matchlist(highlight, 'links to \(\S\+\)')
  if len(link_matches) > 0 " follow the link
    return highlight#get_background_colors(link_matches[1])
  endif

  let ctermbg = highlight#match_highlight(highlight, 'ctermbg=\(\S\+\)')
  let guibg   = highlight#match_highlight(highlight, 'guibg=\(\S\+\)')
  return [guibg, ctermbg]
endfunction

function! highlight#match_highlight(highlight, pattern)
  let matches = matchlist(a:highlight, a:pattern)
  if len(matches) == 0
    return 'NONE'
  endif
  return matches[1]
endfunction
