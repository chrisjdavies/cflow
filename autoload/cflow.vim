" autoload/cflow.vim - Main plugin logic
" Maintainer: Claude
" Version: 1.0.0

let s:save_cpo = &cpo
set cpo&vim

" State variables
let s:is_active = 0
let s:match_ids = []

" Initialize highlight groups
function! s:InitHighlights()
  " Dimmed code highlight
  if !hlexists('CFlowDimmed')
    highlight CFlowDimmed ctermfg=darkgray guifg=#606060
  endif

  " Focused variable highlight
  if !hlexists('CFlowFocused')
    highlight CFlowFocused cterm=bold,underline gui=bold,underline
  endif

  " Dependency highlight (optional)
  if !hlexists('CFlowDependency')
    highlight CFlowDependency ctermfg=cyan guifg=#00afaf
  endif
endfunction

" Public API: Focus on the variable under cursor
function! cflow#Focus()
  if !g:cflow_enabled
    echo "CFlow is disabled. Set g:cflow_enabled = 1 to enable."
    return
  endif

  " Only work on C files
  if &filetype !=# 'c'
    echo "CFlow only works with C files"
    return
  endif

  " Clear any existing highlights
  call cflow#Clear()

  " Initialize highlights
  call s:InitHighlights()

  " Get the word under cursor
  let l:word = expand('<cword>')
  if empty(l:word)
    echo "No word under cursor"
    return
  endif

  " Get cursor position
  let l:line = line('.')
  let l:col = col('.')

  " Analyze the code
  try
    let l:analysis = cflow#analysis#Analyze(l:word, l:line, l:col)

    if empty(l:analysis.relevant_lines)
      echo "No flow analysis results for: " . l:word
      return
    endif

    " Apply highlighting
    call cflow#highlight#ApplyDimming(l:analysis.relevant_lines)

    " Highlight the focused variable if enabled
    if g:cflow_highlight_variable
      call cflow#highlight#HighlightVariable(l:word, l:line)
    endif

    let s:is_active = 1
    echo printf("Focused on '%s' (%d relevant lines)", l:word, len(l:analysis.relevant_lines))
  catch
    echo "Error analyzing code: " . v:exception
    call cflow#Clear()
  endtry
endfunction

" Public API: Clear all highlights
function! cflow#Clear()
  call cflow#highlight#ClearAll()
  let s:is_active = 0
endfunction

" Public API: Toggle focus on/off
function! cflow#Toggle()
  if s:is_active
    call cflow#Clear()
  else
    call cflow#Focus()
  endif
endfunction

" Public API: Show status
function! cflow#Status()
  if s:is_active
    echo "CFlow is active"
  else
    echo "CFlow is inactive"
  endif
  echo "Configuration:"
  echo "  Enabled: " . g:cflow_enabled
  echo "  Dim amount: " . g:cflow_dim_amount . "%"
  echo "  Scope: " . g:cflow_scope
  echo "  Direction: " . g:cflow_direction
  echo "  Auto-clear: " . g:cflow_auto_clear
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
