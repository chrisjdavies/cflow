" run_tests.vim - Manual test runner
" Run with: vim -u NONE -N -S test/run_tests.vim

" Add plugin to runtimepath
set runtimepath+=.

" Source the plugin
source plugin/cflow.vim

" Test counters
let s:total = 0
let s:passed = 0
let s:failed = 0

function! TestResult(name, passed)
  let s:total += 1
  if a:passed
    let s:passed += 1
    echo "✓ " . a:name
  else
    let s:failed += 1
    echo "✗ " . a:name
  endif
endfunction

echo "========================================"
echo "CFlow Plugin Tests"
echo "========================================"
echo ""

" Test 1: Plugin loaded
call TestResult("Plugin loaded", exists('g:loaded_cflow'))

" Test 2: Commands exist
call TestResult("CFlowFocus command exists", exists(':CFlowFocus') == 2)
call TestResult("CFlowClear command exists", exists(':CFlowClear') == 2)
call TestResult("CFlowToggle command exists", exists(':CFlowToggle') == 2)

" Test 3: Configuration variables
call TestResult("g:cflow_enabled exists", exists('g:cflow_enabled'))
call TestResult("g:cflow_dim_amount exists", exists('g:cflow_dim_amount'))
call TestResult("g:cflow_scope exists", exists('g:cflow_scope'))

" Test 4: Autoload functions exist
call TestResult("cflow#Focus function exists", exists('*cflow#Focus'))
call TestResult("cflow#Clear function exists", exists('*cflow#Clear'))

echo ""
echo "========================================"
echo "Testing Parser Module"
echo "========================================"
echo ""

" Test 5: Extract RHS variables
let l:line = "int b = a + 10;"
let l:vars = cflow#parser#ExtractRHSVariables(l:line)
call TestResult("Extract 'a' from 'int b = a + 10;'", index(l:vars, 'a') != -1)

" Test 6: Multiple variables
let l:line = "int c = a + b * d;"
let l:vars = cflow#parser#ExtractRHSVariables(l:line)
call TestResult("Extract 'a' from complex RHS", index(l:vars, 'a') != -1)
call TestResult("Extract 'b' from complex RHS", index(l:vars, 'b') != -1)
call TestResult("Extract 'd' from complex RHS", index(l:vars, 'd') != -1)

" Test 7: Don't extract keywords
let l:line = "int result = sizeof(int) + a;"
let l:vars = cflow#parser#ExtractRHSVariables(l:line)
call TestResult("Don't extract 'sizeof' keyword", index(l:vars, 'sizeof') == -1)
call TestResult("Don't extract 'int' keyword", index(l:vars, 'int') == -1)

" Test 8: Extract condition variables
let l:line = "if (a > b && c < d)"
let l:vars = cflow#parser#ExtractConditionVars(l:line)
call TestResult("Extract 'a' from if condition", index(l:vars, 'a') != -1)
call TestResult("Extract 'b' from if condition", index(l:vars, 'b') != -1)

echo ""
echo "========================================"
echo "Testing with Fixture Files"
echo "========================================"
echo ""

" Test 9: Load simple fixture
edit test/fixtures/simple.c
set filetype=c
call TestResult("Simple fixture loaded", line('$') > 0)

" Test 10: Analyze variable
execute 'normal! 9G'
let l:word = 'result'
try
  let l:analysis = cflow#analysis#Analyze(l:word, 9, 1)
  call TestResult("Analysis completed without error", 1)
  call TestResult("Analysis found relevant lines", len(l:analysis.relevant_lines) > 0)
catch
  call TestResult("Analysis completed without error", 0)
  call TestResult("Analysis found relevant lines", 0)
endtry

" Test 11: Load control flow fixture
edit test/fixtures/control_flow.c
set filetype=c
call TestResult("Control flow fixture loaded", line('$') > 0)

" Test 12: Load complex fixture
edit test/fixtures/complex.c
set filetype=c
call TestResult("Complex fixture loaded", line('$') > 0)

echo ""
echo "========================================"
echo "Results"
echo "========================================"
echo printf("Total:  %d", s:total)
echo printf("Passed: %d", s:passed)
echo printf("Failed: %d", s:failed)
echo "========================================"

if s:failed == 0
  echo "✓ All tests passed!"
  qall!
else
  echo "✗ Some tests failed!"
  cquit!
endif
