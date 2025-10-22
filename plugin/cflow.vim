" cflow.vim - Code focus plugin for C files
" Maintainer: Claude
" Version: 1.0.0

if exists('g:loaded_cflow')
  finish
endif
let g:loaded_cflow = 1

" Save user's cpoptions and reset to vim defaults
let s:save_cpo = &cpo
set cpo&vim

" Configuration variables with defaults
if !exists('g:cflow_enabled')
  let g:cflow_enabled = 1
endif

if !exists('g:cflow_dim_amount')
  let g:cflow_dim_amount = 60
endif

if !exists('g:cflow_scope')
  let g:cflow_scope = 'function'
endif

if !exists('g:cflow_highlight_variable')
  let g:cflow_highlight_variable = 1
endif

if !exists('g:cflow_auto_clear')
  let g:cflow_auto_clear = 0
endif

if !exists('g:cflow_direction')
  let g:cflow_direction = 'both'
endif

" Commands
command! -nargs=0 CFlowFocus call cflow#Focus()
command! -nargs=0 CFlowClear call cflow#Clear()
command! -nargs=0 CFlowToggle call cflow#Toggle()
command! -nargs=0 CFlowStatus call cflow#Status()

" Default mappings (can be disabled by user)
if !exists('g:cflow_no_mappings')
  nnoremap <silent> <leader>cf :CFlowFocus<CR>
  nnoremap <silent> <leader>cc :CFlowClear<CR>
  nnoremap <silent> <leader>ct :CFlowToggle<CR>
endif

" Auto-clear on cursor move if configured
if g:cflow_auto_clear
  augroup cflow_auto
    autocmd!
    autocmd CursorMoved * call cflow#Clear()
  augroup END
endif

" Restore user's cpoptions
let &cpo = s:save_cpo
unlet s:save_cpo
