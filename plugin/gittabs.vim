vim9script

def g:CreateTabAndTabSelHighlightGroups(name: string): void
	var ctermbg = synIDattr(synIDtrans(hlID('TabLine')), 'bg', 'cterm')
	var guibg = synIDattr(synIDtrans(hlID('TabLine')), 'bg', 'gui')
	var ctermbg_sel = synIDattr(synIDtrans(hlID('TabLineSel')), 'bg', 'cterm')
	var guibg_sel = synIDattr(synIDtrans(hlID('TabLineSel')), 'bg', 'gui')

	var unselected_tab = hlget(name, 1)[0]
	unselected_tab.name = "Tab" .. name
	unselected_tab.cterm = {'bold': v:true}
	unselected_tab.ctermbg = ctermbg != "" ?  ctermbg : 'NONE'
	unselected_tab.guibg = guibg != "" ?  guibg : 'NONE'


	var selected_tab = hlget(name, 1)[0]
	selected_tab.name = "Tab" .. name .. "Sel"
	selected_tab.cterm = {'bold': v:true}
	selected_tab.ctermbg = ctermbg_sel != "" ?  ctermbg_sel : 'NONE'
	selected_tab.guibg = guibg_sel != "" ?  guibg_sel : 'NONE'

	hlset([unselected_tab, selected_tab])
enddef

def g:TabLineColors(): void
	# Make a custom highlight group from Title in order to mimic the default
	# highlight behavior of tabline for when multiple windows are open in a tab
  var ctermbg = synIDattr(synIDtrans(hlID('TabLine')), 'bg', 'cterm')
  var guibg = synIDattr(synIDtrans(hlID('TabLine')), 'bg', 'gui')
  var ctermbg_sel = synIDattr(synIDtrans(hlID('TabLineSel')), 'bg', 'cterm')
  var guibg_sel = synIDattr(synIDtrans(hlID('TabLineSel')), 'bg', 'gui')

  g:CreateTabAndTabSelHighlightGroups('Title')
  g:CreateTabAndTabSelHighlightGroups('DiffAdd')
  g:CreateTabAndTabSelHighlightGroups('DiffChange')
  g:CreateTabAndTabSelHighlightGroups('DiffDelete')

enddef

g:TabLineColors()

autocmd ColorScheme * call TabLineColors()

def g:MyTabLabel(n: number, selected: bool): string
	var buflist = tabpagebuflist(n)
	var winnr = tabpagewinnr(n)
	var buffer_name = bufname(buflist[winnr - 1])
	var modified = getbufinfo(buflist[winnr - 1])[0].changed ? ' +' : ''
	if buffer_name == ''
		return '[No Name]' .. modified
	endif
	var full_path = fnamemodify(buffer_name, ':p')
	var display_name = fnamemodify(buffer_name, ':~:.')
	if display_name == full_path
		# This happens if the file is outside out current working directory
		display_name = fnamemodify(buffer_name, ':t')
	endif
	var gst = system('git status --porcelain=v1 ' .. full_path)
	# If the output is blank, then it's a file tracked by git with
	# no modifications
	# After that we look at the first two letters of the output
	# For a staged file named 'staged', a modified file named 'modified',
	# a staged and modified file named 'staged_and_modified, and an
	# untracked file named 'untracked' the output of git status
	# --porcelain looks like this:
	# M  staged
	#  M modified
	# MM staged_and_modified
	# ?? untracked
	# So if 'M' is in the first column, we display an A, if it's in the
	# second column we display and M (even if we already have an A from the
	# first column,), and if it's ?? we display U for untracked.
	var letter = ''
	var sel_suffix = selected ? 'Sel' : ''
	if gst != ''
		var prefix = gst[0 : 1]
		if prefix[0] == 'M'
			letter ..= '%#TabDiffAdd' .. sel_suffix .. '#A'
		endif
		if prefix[1] == 'M'
			letter ..= '%#TabDiffChange' .. sel_suffix .. '#M'
		elseif prefix == '??'
			letter = '%#TabDiffDelete' .. sel_suffix .. '#U'
		endif
	endif
	if letter != ''
		return display_name .. modified .. ' ' .. letter
	endif
	return display_name .. modified
enddef


def g:MyTabLine(): string
  var s = ''
	for i in range(tabpagenr('$'))
		# select the highlighting
		var highlight_g = '%#TabLine#'
		var title_g = '%#TabTitle#'
		var selected = i + 1 == tabpagenr()
		if selected
			highlight_g = '%#TabLineSel#'
			title_g = '%#TabTitleSel#'
		endif
		s ..= highlight_g
		# set the tab page number (for mouse clicks)
		s ..= '%' .. (i + 1) .. 'T'

		# Put the number of windows in this tab
		var num_windows = tabpagewinnr(i + 1, '$')
		if num_windows > 1
			s ..= title_g .. ' ' .. num_windows .. '' .. highlight_g
		endif

		# the label is made by MyTabLabel
		s ..= ' %{%MyTabLabel(' .. (i + 1) .. ', v:' ..  selected  .. ')%} '
	endfor

	# after the last tab fill with TabLineFill and reset tab page nr
	s ..= '%#TabLineFill#%T'

	# right align the label to close the current tab page
	if tabpagenr('$') > 1
		s ..= '%=%#TabLine#%999Xclose'
	endif

	return s
enddef


set tabline=%!MyTabLine()
