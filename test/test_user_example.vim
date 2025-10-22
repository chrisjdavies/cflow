" Test the exact example the user provided
" When we focus on 'ep', and there's a line 'cp = foo(ep);'
" then 'cp' should also be followed and not dimmed

set runtimepath+=.
source plugin/cflow.vim

echo "======================================"
echo "Testing User's Example: cp = foo(ep)"
echo "======================================"
echo ""

" Create test buffer with the exact scenario
enew
setlocal filetype=c
call setline(1, 'int test(int ep) {')
call setline(2, '    int cp = foo(ep);')
call setline(3, '    int result = cp * 2;')
call setline(4, '    int unrelated = 100;')
call setline(5, '    return result;')
call setline(6, '}')

" Focus on 'ep'
let analysis = cflow#analysis#Analyze('ep', 1, 1)
let relevant = map(copy(analysis.relevant_lines), 'str2nr(v:val)')

echo "When focusing on 'ep':"
echo ""
echo "Dependency Graph:"
for [key, node] in items(analysis.dependencies)
    echo "  Line " . key . ": " . node.target . " = f(" . join(node.depends_on, ', ') . ")"
endfor
echo ""

echo "Results:"
echo "  Line 2 (cp = foo(ep)):"
if index(relevant, 2) != -1
    echo "    ✓ VISIBLE (correct - cp is derived from ep)"
else
    echo "    ✗ DIMMED (wrong - cp should be visible!)"
endif

echo ""
echo "  Line 3 (result = cp * 2):"
if index(relevant, 3) != -1
    echo "    ✓ VISIBLE (correct - result uses cp, which derives from ep)"
else
    echo "    ✗ DIMMED (wrong - result should be visible because it uses cp!)"
endif

echo ""
echo "  Line 4 (unrelated = 100):"
if index(relevant, 4) == -1
    echo "    ✓ DIMMED (correct - unrelated doesn't use ep or derived variables)"
else
    echo "    ~ VISIBLE (acceptable - conservative analysis)"
endif

echo ""
echo "Summary: Variable flow tracking"
if index(relevant, 2) != -1 && index(relevant, 3) != -1
    echo "  ✓ SUCCESS: Forward slicing correctly follows ep → cp → result"
else
    echo "  ✗ FAILURE: Forward slicing not working correctly"
endif

echo ""
echo "======================================"
echo ""
qall!
