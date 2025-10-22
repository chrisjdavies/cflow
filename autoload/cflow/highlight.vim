" autoload/cflow/highlight.vim - Visualization and highlighting
" Maintainer: Claude
" Version: 1.0.0

let s:save_cpo = &cpo
set cpo&vim

" Store match IDs for cleanup
let s:match_ids = []

" Apply dimming to all lines except the relevant ones
function! cflow#highlight#ApplyDimming(relevant_lines)
  " Convert relevant lines to a dictionary for fast lookup
  let l:relevant = {}
  for l:line in a:relevant_lines
    let l:relevant[str2nr(l:line)] = 1
  endfor

  " Get total line count
  let l:total_lines = line('$')

  " Build list of line ranges to dim
  let l:dim_lines = []
  for l:lnum in range(1, l:total_lines)
    if !has_key(l:relevant, l:lnum)
      call add(l:dim_lines, l:lnum)
    endif
  endfor

  " Apply dimming in chunks (matchaddpos has a limit of 8 items per call)
  let l:chunk_size = 8
  let l:idx = 0

  while l:idx < len(l:dim_lines)
    let l:end_idx = min([l:idx + l:chunk_size, len(l:dim_lines)])
    let l:chunk = l:dim_lines[l:idx : l:end_idx - 1]

    " Convert to list of lists (required by matchaddpos)
    let l:positions = []
    for l:line in l:chunk
      call add(l:positions, [l:line])
    endfor

    if !empty(l:positions)
      let l:match_id = matchaddpos('CFlowDimmed', l:positions, 10)
      call add(s:match_ids, l:match_id)
    endif

    let l:idx = l:end_idx
  endwhile
endfunction

" Highlight the focused variable
function! cflow#highlight#HighlightVariable(variable, line)
  " Highlight all occurrences of the variable in visible area
  let l:pattern = '\<' . a:variable . '\>'

  try
    let l:match_id = matchadd('CFlowFocused', l:pattern, 11)
    call add(s:match_ids, l:match_id)
  catch
    " Pattern might be invalid, skip highlighting
  endtry
endfunction

" Clear all highlights
function! cflow#highlight#ClearAll()
  " Remove all matches
  for l:id in s:match_ids
    try
      call matchdelete(l:id)
    catch
      " Match might already be deleted
    endtry
  endfor

  let s:match_ids = []
endfunction

" Get current match count (for debugging)
function! cflow#highlight#GetMatchCount()
  return len(s:match_ids)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
