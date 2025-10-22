" Manual test for variable flow
set runtimepath+=.
source plugin/cflow.vim

" Create a simple test buffer
enew
setlocal filetype=c
call setline(1, 'int test_function(int ep) {')
call setline(2, '    int cp = foo(ep);')
call setline(3, '    int result = cp * 2;')
call setline(4, '    int unrelated = 100;')
call setline(5, '    return result;')
call setline(6, '}')

" Test the parser first
echo "=== Testing Parser ==="
let line2 = getline(2)
echo "Line 2: " . line2
let rhs_vars = cflow#parser#ExtractRHSVariables(line2)
echo "RHS variables: " . string(rhs_vars)
echo "Should contain 'ep': " . (index(rhs_vars, 'ep') != -1 ? 'YES' : 'NO')
echo ""

let line3 = getline(3)
echo "Line 3: " . line3
let rhs_vars = cflow#parser#ExtractRHSVariables(line3)
echo "RHS variables: " . string(rhs_vars)
echo "Should contain 'cp': " . (index(rhs_vars, 'cp') != -1 ? 'YES' : 'NO')
echo ""

" Test the analysis
echo "=== Testing Analysis ==="
let analysis = cflow#analysis#Analyze('ep', 1, 1)
echo "Relevant lines: " . string(analysis.relevant_lines)
echo ""

" Check specific lines
let relevant_nums = map(copy(analysis.relevant_lines), 'str2nr(v:val)')
echo "Line 2 (cp = foo(ep)) included: " . (index(relevant_nums, 2) != -1 ? 'YES' : 'NO')
echo "Line 3 (result = cp * 2) included: " . (index(relevant_nums, 3) != -1 ? 'YES' : 'NO')
echo "Line 4 (unrelated) included: " . (index(relevant_nums, 4) != -1 ? 'NO (correct)' : 'YES (correct)')
echo "Line 5 (return result) included: " . (index(relevant_nums, 5) != -1 ? 'YES' : 'NO')

" Show dependency graph
echo ""
echo "=== Dependency Graph ==="
for [key, node] in items(analysis.dependencies)
    echo "Line " . key . ": target=" . node.target . ", depends_on=" . string(node.depends_on)
endfor

echo ""
echo "Press Enter to quit"
call getchar()
qall!
