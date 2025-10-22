" test/test_runner.vim - Test framework for cflow
" Maintainer: Claude
" Version: 1.0.0

let s:tests_run = 0
let s:tests_passed = 0
let s:tests_failed = 0
let s:test_failures = []

" Reset test counters
function! s:ResetTests()
  let s:tests_run = 0
  let s:tests_passed = 0
  let s:tests_failed = 0
  let s:test_failures = []
endfunction

" Assert that a condition is true
function! Assert(condition, message)
  let s:tests_run += 1

  if a:condition
    let s:tests_passed += 1
    echo "  ✓ " . a:message
  else
    let s:tests_failed += 1
    let l:failure = "  ✗ " . a:message
    echo l:failure
    call add(s:test_failures, l:failure)
  endif
endfunction

" Assert equality
function! AssertEqual(expected, actual, message)
  let s:tests_run += 1

  if a:expected ==# a:actual
    let s:tests_passed += 1
    echo "  ✓ " . a:message
  else
    let s:tests_failed += 1
    let l:failure = printf("  ✗ %s (expected: %s, got: %s)",
      \ a:message, string(a:expected), string(a:actual))
    echo l:failure
    call add(s:test_failures, l:failure)
  endif
endfunction

" Assert that a list contains an item
function! AssertContains(list, item, message)
  let s:tests_run += 1

  if index(a:list, a:item) != -1
    let s:tests_passed += 1
    echo "  ✓ " . a:message
  else
    let s:tests_failed += 1
    let l:failure = printf("  ✗ %s (list: %s, item: %s)",
      \ a:message, string(a:list), string(a:item))
    echo l:failure
    call add(s:test_failures, l:failure)
  endif
endfunction

" Print test results
function! s:PrintResults()
  echo ""
  echo "================================"
  echo "Test Results"
  echo "================================"
  echo printf("Total:  %d", s:tests_run)
  echo printf("Passed: %d", s:tests_passed)
  echo printf("Failed: %d", s:tests_failed)

  if s:tests_failed > 0
    echo ""
    echo "Failures:"
    for l:failure in s:test_failures
      echo l:failure
    endfor
  endif

  echo "================================"

  if s:tests_failed == 0
    echo "All tests passed!"
    return 0
  else
    echo "Some tests failed!"
    return 1
  endif
endfunction

" Run all tests
function! RunAllTests()
  call s:ResetTests()

  echo "Running cflow tests..."
  echo ""

  " Source all test files
  for l:test_file in glob(expand('<sfile>:p:h') . '/test_*.vim', 0, 1)
    if l:test_file !~ 'test_runner\.vim'
      echo "Running: " . fnamemodify(l:test_file, ':t')
      execute 'source' l:test_file
      echo ""
    endif
  endfor

  return s:PrintResults()
endfunction

" Command to run tests
command! CFlowTest call RunAllTests()
