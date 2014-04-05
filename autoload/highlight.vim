function! highlight#define_sign_column_highlight()
  highlight default link SignColumn LineNr
endfunction

function! highlight#define_highlights()
  redir => sign_highlight
  silent highlight SignColumn
  redir END
  let sign_ctermbg = matchlist(sign_highlight, 'ctermbg=\(\S\+\)')[1]
  let sign_guibg   = matchlist(sign_highlight,   'guibg=\(\S\+\)')[1]

  " Highlights used by the signs.
  execute "highlight GitGutterAddDefault    guifg=#009900 guibg=".sign_guibg." ctermfg=2 ctermbg=".sign_ctermbg
  execute "highlight GitGutterChangeDefault guifg=#bbbb00 guibg=".sign_guibg." ctermfg=3 ctermbg=".sign_ctermbg
  execute "highlight GitGutterDeleteDefault guifg=#ff2222 guibg=".sign_guibg." ctermfg=1 ctermbg=".sign_ctermbg
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
