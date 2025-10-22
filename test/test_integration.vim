" test/test_integration.vim - Integration tests
" Maintainer: Claude

echo "Testing Integration"

" Helper function to load a fixture and test analysis
function! TestFixture(file, line, variable, expected_lines)
  let l:fixture_path = expand('<sfile>:p:h') . '/fixtures/' . a:file

  " Open the fixture file
  execute 'edit' l:fixture_path

  " Set filetype to C
  set filetype=c

  " Move to the test line
  execute 'normal! ' . a:line . 'G'

  " Get the analysis
  let l:analysis = cflow#analysis#Analyze(a:variable, a:line, 1)

  " Check if expected lines are in relevant_lines
  let l:success = 1
  for l:expected in a:expected_lines
    if index(l:analysis.relevant_lines, string(l:expected)) == -1
      let l:success = 0
      break
    endif
  endfor

  return l:success
endfunction

" Test 1: Simple data flow
let l:result = TestFixture('simple.c', 9, 'c', [4, 5, 6, 9])
call Assert(l:result, "Simple fixture: focusing on 'c' includes lines 4,5,6,9")

" Test 2: Control flow
let l:result = TestFixture('control_flow.c', 15, 'result', [4, 7, 8, 10, 15])
call Assert(l:result, "Control flow fixture: focusing on 'result' includes lines 4,7,8,10,15")

" Test 3: Complex with loops
let l:result = TestFixture('complex.c', 15, 'sum', [4, 8, 9, 15])
call Assert(l:result, "Complex fixture: focusing on 'sum' includes lines 4,8,9,15")
