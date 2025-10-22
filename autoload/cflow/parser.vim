" autoload/cflow/parser.vim - C code parser
" Maintainer: Claude
" Version: 1.0.0

let s:save_cpo = &cpo
set cpo&vim

" Parse the current buffer and extract variable information
function! cflow#parser#ParseBuffer()
  let l:result = {
    \ 'variables': {},
    \ 'functions': {},
    \ 'scope_stack': []
    \ }

  let l:lines = getline(1, '$')
  let l:scope_level = 0
  let l:current_function = ''

  for l:lnum in range(1, len(l:lines))
    let l:line = l:lines[l:lnum - 1]

    " Track scope with braces
    let l:open_braces = count(l:line, '{')
    let l:close_braces = count(l:line, '}')

    " Detect function definitions
    let l:func_match = matchlist(l:line, '^\s*\w\+\s\+\(\w\+\)\s*(')
    if !empty(l:func_match) && l:scope_level == 0
      let l:current_function = l:func_match[1]
      let l:result.functions[l:current_function] = {
        \ 'start_line': l:lnum,
        \ 'end_line': -1
        \ }
    endif

    " Update scope level
    let l:scope_level += l:open_braces - l:close_braces

    " Mark function end
    if l:scope_level == 0 && !empty(l:current_function) && l:close_braces > 0
      let l:result.functions[l:current_function].end_line = l:lnum
      let l:current_function = ''
    endif
  endfor

  return l:result
endfunction

" Find the function containing the given line
function! cflow#parser#FindContainingFunction(line)
  let l:parse_result = cflow#parser#ParseBuffer()

  for [l:fname, l:finfo] in items(l:parse_result.functions)
    if l:finfo.start_line <= a:line &&
       \ (l:finfo.end_line >= a:line || l:finfo.end_line == -1)
      return l:finfo
    endif
  endfor

  " No function found, return whole file
  return {'start_line': 1, 'end_line': line('$')}
endfunction

" Extract all occurrences of a variable in a line range
function! cflow#parser#FindVariableRefs(variable, start_line, end_line)
  let l:refs = []

  for l:lnum in range(a:start_line, a:end_line)
    let l:line = getline(l:lnum)

    " Find all occurrences of the variable (as a whole word)
    let l:pattern = '\<' . a:variable . '\>'
    let l:col = 0

    while 1
      let l:match_col = match(l:line, l:pattern, l:col)
      if l:match_col == -1
        break
      endif

      call add(l:refs, {
        \ 'line': l:lnum,
        \ 'col': l:match_col + 1,
        \ 'text': l:line,
        \ 'type': s:DetermineRefType(l:line, l:match_col, a:variable)
        \ })

      let l:col = l:match_col + len(a:variable)
    endwhile
  endfor

  return l:refs
endfunction

" Determine if a variable reference is a read, write, or both
function! s:DetermineRefType(line, col, variable)
  let l:before = strpart(a:line, 0, a:col)
  let l:after = strpart(a:line, a:col + len(a:variable))

  " Check for assignment
  if l:after =~ '^\s*=' && l:after !~ '^\s*=='
    return 'write'
  endif

  " Check for increment/decrement
  if l:after =~ '^\s*++\|^\s*--' || l:before =~ '++\s*$\|--\s*$'
    return 'both'
  endif

  " Check for compound assignment
  if l:after =~ '^\s*+=\|^\s*-=\|^\s*\*=\|^\s*/=\|^\s*%='
    return 'both'
  endif

  " Default is read
  return 'read'
endfunction

" Extract variables from the right-hand side of an assignment
function! cflow#parser#ExtractRHSVariables(line)
  " Find the assignment operator
  let l:eq_pos = match(a:line, '\s=\s')
  if l:eq_pos == -1
    return []
  endif

  " Get everything after the '='
  let l:rhs = strpart(a:line, l:eq_pos + 2)

  " Remove semicolon and comments
  let l:rhs = substitute(l:rhs, '//.*$', '', '')
  let l:rhs = substitute(l:rhs, '/\*.*\*/', '', '')
  let l:rhs = substitute(l:rhs, ';.*$', '', '')

  " Extract identifiers (simple variable names)
  let l:vars = []
  let l:pattern = '\<\([a-zA-Z_][a-zA-Z0-9_]*\)\>'
  let l:pos = 0

  while 1
    let l:match = matchlist(l:rhs, l:pattern, l:pos)
    if empty(l:match)
      break
    endif

    let l:var = l:match[1]
    " Skip C keywords and function calls
    if !s:IsCKeyword(l:var) && !s:IsFunctionCall(l:rhs, match(l:rhs, l:pattern, l:pos))
      if index(l:vars, l:var) == -1
        call add(l:vars, l:var)
      endif
    endif

    let l:pos = match(l:rhs, l:pattern, l:pos) + len(l:var)
  endwhile

  return l:vars
endfunction

" Check if a word is a C keyword
function! s:IsCKeyword(word)
  let l:keywords = [
    \ 'if', 'else', 'while', 'for', 'do', 'switch', 'case', 'default',
    \ 'break', 'continue', 'return', 'goto',
    \ 'int', 'char', 'float', 'double', 'void', 'long', 'short',
    \ 'unsigned', 'signed', 'const', 'static', 'extern', 'register',
    \ 'struct', 'union', 'enum', 'typedef',
    \ 'sizeof', 'auto', 'volatile'
    \ ]
  return index(l:keywords, a:word) != -1
endfunction

" Check if a position in a string is followed by '(' (function call)
function! s:IsFunctionCall(text, pos)
  let l:after = strpart(a:text, a:pos)
  return l:after =~ '^\w\+\s*('
endfunction

" Find control flow statements that affect a line range
function! cflow#parser#FindControlFlow(start_line, end_line)
  let l:control_lines = []

  for l:lnum in range(a:start_line, a:end_line)
    let l:line = getline(l:lnum)

    " Check for control flow keywords
    if l:line =~ '^\s*\(if\|while\|for\|switch\)\s*('
      call add(l:control_lines, l:lnum)
    endif
  endfor

  return l:control_lines
endfunction

" Find the condition variables in a control flow statement
function! cflow#parser#ExtractConditionVars(line)
  " Extract the condition from if/while/for statements
  let l:match = matchlist(a:line, '^\s*\(if\|while\|for\)\s*(\s*\(.\{-}\)\s*)')
  if empty(l:match)
    return []
  endif

  let l:condition = l:match[2]

  " Extract variables from the condition
  let l:vars = []
  let l:pattern = '\<\([a-zA-Z_][a-zA-Z0-9_]*\)\>'
  let l:pos = 0

  while 1
    let l:match = matchlist(l:condition, l:pattern, l:pos)
    if empty(l:match)
      break
    endif

    let l:var = l:match[1]
    if !s:IsCKeyword(l:var)
      if index(l:vars, l:var) == -1
        call add(l:vars, l:var)
      endif
    endif

    let l:pos = match(l:condition, l:pattern, l:pos) + len(l:var)
  endwhile

  return l:vars
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
