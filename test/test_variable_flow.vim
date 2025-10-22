" test/test_variable_flow.vim - Test variable flow tracking
" This tests that forward slicing correctly follows derived variables

echo "Testing Variable Flow Tracking"
echo ""

" Load the fixture
let l:fixture = expand('<sfile>:p:h') . '/fixtures/variable_flow.c'
execute 'edit' l:fixture
set filetype=c

" Test focusing on 'ep' at line 12
" We need to check that derived variables are followed
echo "Test: Focus on 'ep' - should follow derived variables"

" Move to line 12 and analyze
execute 'normal! 12G'
let l:analysis = cflow#analysis#Analyze('ep', 12, 1)

echo "  Relevant lines found: " . string(l:analysis.relevant_lines)

" Convert to numbers for easier checking
let l:relevant_nums = []
for l:line in l:analysis.relevant_lines
    call add(l:relevant_nums, str2nr(l:line))
endfor

" These lines should be visible (relevant to ep):
let l:expected_visible = [14, 16, 18, 22, 24]

echo ""
echo "  Checking expected visible lines:"
for l:line in l:expected_visible
    if index(l:relevant_nums, l:line) != -1
        echo "    ✓ Line " . l:line . " is visible"
    else
        echo "    ✗ Line " . l:line . " is MISSING (should be visible!)"
    endif
endfor

" Line 20 should be dimmed (unrelated)
echo ""
echo "  Checking dimmed lines:"
if index(l:relevant_nums, 20) == -1
    echo "    ✓ Line 20 (unrelated) is correctly dimmed"
else
    echo "    ✗ Line 20 (unrelated) is visible (should be dimmed!)"
endif

" Specific check for the user's example: cp = foo(ep)
echo ""
echo "  Specific checks:"
if index(l:relevant_nums, 16) != -1
    echo "    ✓ Line 16 (cp = foo(ep)) is visible"
else
    echo "    ✗ Line 16 (cp = foo(ep)) is MISSING"
endif

if index(l:relevant_nums, 18) != -1
    echo "    ✓ Line 18 (result = cp * 2) is visible - cp is being followed!"
else
    echo "    ✗ Line 18 (result = cp * 2) is MISSING - cp is NOT being followed!"
endif

echo ""
