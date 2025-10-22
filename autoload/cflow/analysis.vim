" autoload/cflow/analysis.vim - Data flow analysis
" Maintainer: Claude
" Version: 1.0.0

let s:save_cpo = &cpo
set cpo&vim

" Main analysis function
function! cflow#analysis#Analyze(variable, line, col)
  " Determine scope based on configuration
  if g:cflow_scope ==# 'function'
    let l:scope = cflow#parser#FindContainingFunction(a:line)
  else
    " File scope
    let l:scope = {'start_line': 1, 'end_line': line('$')}
  endif

  " Find all references to the variable
  let l:refs = cflow#parser#FindVariableRefs(a:variable, l:scope.start_line, l:scope.end_line)

  if empty(l:refs)
    return {'relevant_lines': [], 'dependencies': {}}
  endif

  " Build dependency graph
  let l:dep_graph = s:BuildDependencyGraph(l:refs, a:variable, l:scope)

  " Perform slicing based on direction
  let l:relevant_lines = {}

  if g:cflow_direction ==# 'backward' || g:cflow_direction ==# 'both'
    let l:backward = s:BackwardSlice(a:line, a:variable, l:dep_graph, l:scope)
    call extend(l:relevant_lines, l:backward)
  endif

  if g:cflow_direction ==# 'forward' || g:cflow_direction ==# 'both'
    let l:forward = s:ForwardSlice(a:line, a:variable, l:dep_graph, l:scope)
    call extend(l:relevant_lines, l:forward)
  endif

  " Include control flow statements
  let l:control_lines = s:FindRelevantControlFlow(l:relevant_lines, l:scope)
  call extend(l:relevant_lines, l:control_lines)

  " Always include the current line
  let l:relevant_lines[a:line] = 1

  return {
    \ 'relevant_lines': sort(keys(l:relevant_lines), {a, b -> str2nr(a) - str2nr(b)}),
    \ 'dependencies': l:dep_graph
    \ }
endfunction

" Build a dependency graph from variable references
function! s:BuildDependencyGraph(refs, variable, scope)
  let l:graph = {}

  for l:ref in a:refs
    if l:ref.type ==# 'write' || l:ref.type ==# 'both'
      " This is an assignment or modification
      let l:line_key = string(l:ref.line)

      if !has_key(l:graph, l:line_key)
        let l:graph[l:line_key] = {
          \ 'line': l:ref.line,
          \ 'type': 'write',
          \ 'target': a:variable,
          \ 'depends_on': []
          \ }
      endif

      " Extract variables from RHS
      let l:rhs_vars = cflow#parser#ExtractRHSVariables(l:ref.text)
      let l:graph[l:line_key].depends_on = l:rhs_vars
    endif

    if l:ref.type ==# 'read' || l:ref.type ==# 'both'
      " This is a read
      let l:line_key = string(l:ref.line)

      if !has_key(l:graph, l:line_key)
        let l:graph[l:line_key] = {
          \ 'line': l:ref.line,
          \ 'type': 'read',
          \ 'target': a:variable,
          \ 'depends_on': [a:variable]
          \ }
      endif
    endif
  endfor

  return l:graph
endfunction

" Perform backward slicing (find what influences the variable)
function! s:BackwardSlice(start_line, variable, graph, scope)
  let l:relevant = {}
  let l:visited = {}
  let l:queue = [[a:start_line, a:variable]]

  while !empty(l:queue)
    let [l:line, l:var] = remove(l:queue, 0)
    let l:key = l:line . ':' . l:var

    if has_key(l:visited, l:key)
      continue
    endif
    let l:visited[l:key] = 1

    " Find all writes to this variable before this line
    for l:dep_line in range(a:scope.start_line, l:line)
      let l:line_key = string(l:dep_line)

      if has_key(a:graph, l:line_key)
        let l:node = a:graph[l:line_key]

        " If this line writes to our variable
        if l:node.target ==# l:var && (l:node.type ==# 'write' || l:node.type ==# 'both')
          let l:relevant[l:dep_line] = 1

          " Add dependencies to queue
          for l:dep_var in l:node.depends_on
            call add(l:queue, [l:dep_line, l:dep_var])
          endfor
        endif
      endif
    endfor

    " Also include all reads of the variable up to this line
    for l:dep_line in range(a:scope.start_line, l:line)
      let l:line_key = string(l:dep_line)

      if has_key(a:graph, l:line_key)
        let l:node = a:graph[l:line_key]
        if l:node.target ==# l:var
          let l:relevant[l:dep_line] = 1
        endif
      endif
    endfor
  endwhile

  return l:relevant
endfunction

" Perform forward slicing (find what the variable influences)
function! s:ForwardSlice(start_line, variable, graph, scope)
  let l:relevant = {}
  let l:visited = {}
  let l:queue = [[a:start_line, a:variable]]

  while !empty(l:queue)
    let [l:line, l:var] = remove(l:queue, 0)
    let l:key = l:line . ':' . l:var

    if has_key(l:visited, l:key)
      continue
    endif
    let l:visited[l:key] = 1

    " Find all uses and assignments after this line
    for l:dep_line in range(l:line, a:scope.end_line)
      let l:line_key = string(l:dep_line)

      if has_key(a:graph, l:line_key)
        let l:node = a:graph[l:line_key]

        " If this line reads from our variable
        if index(l:node.depends_on, l:var) != -1
          let l:relevant[l:dep_line] = 1

          " If it assigns to another variable, track that
          if l:node.type ==# 'write' && l:node.target !=# l:var
            call add(l:queue, [l:dep_line, l:node.target])
          endif
        endif

        " If this line is a read/use of our variable
        if l:node.target ==# l:var && l:node.type ==# 'read'
          let l:relevant[l:dep_line] = 1
        endif
      endif
    endfor
  endwhile

  return l:relevant
endfunction

" Find control flow statements relevant to the given lines
function! s:FindRelevantControlFlow(relevant_lines, scope)
  let l:control = {}
  let l:control_stack = []

  for l:lnum in range(a:scope.start_line, a:scope.end_line)
    let l:line = getline(l:lnum)

    " Track control flow nesting
    if l:line =~ '^\s*\(if\|while\|for\|switch\)\s*('
      call add(l:control_stack, l:lnum)
    endif

    " Check if this line is relevant
    if has_key(a:relevant_lines, l:lnum)
      " Include all control flow statements in the stack
      for l:ctrl_line in l:control_stack
        let l:control[l:ctrl_line] = 1

        " Extract variables from control flow condition
        let l:ctrl_text = getline(l:ctrl_line)
        let l:ctrl_vars = cflow#parser#ExtractConditionVars(l:ctrl_text)

        " If control flow uses any relevant variable, mark it relevant
        for l:var in l:ctrl_vars
          " This would need more sophisticated analysis
          " For now, include the control statement
        endfor
      endfor
    endif

    " Pop from stack on closing brace (simplified)
    if l:line =~ '^\s*}'
      if !empty(l:control_stack)
        call remove(l:control_stack, -1)
      endif
    endif
  endfor

  return l:control
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
