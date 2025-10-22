" test/test_parser.vim - Tests for parser module
" Maintainer: Claude

echo "Testing Parser Module"

" Test: Extract RHS variables from simple assignment
let l:line = "int b = a + 10;"
let l:result = cflow#parser#ExtractRHSVariables(l:line)
call AssertContains(l:result, 'a', "Extract 'a' from simple assignment")

" Test: Extract multiple variables from RHS
let l:line = "int c = a + b * d;"
let l:result = cflow#parser#ExtractRHSVariables(l:line)
call AssertContains(l:result, 'a', "Extract 'a' from multi-variable RHS")
call AssertContains(l:result, 'b', "Extract 'b' from multi-variable RHS")
call AssertContains(l:result, 'd', "Extract 'd' from multi-variable RHS")

" Test: Don't extract keywords
let l:line = "int result = sizeof(int) + a;"
let l:result = cflow#parser#ExtractRHSVariables(l:line)
call Assert(index(l:result, 'sizeof') == -1, "Don't extract keyword 'sizeof'")
call Assert(index(l:result, 'int') == -1, "Don't extract keyword 'int'")
call AssertContains(l:result, 'a', "Extract 'a' even with keywords")

" Test: Extract condition variables
let l:line = "if (a > b && c < d)"
let l:result = cflow#parser#ExtractConditionVars(l:line)
call AssertContains(l:result, 'a', "Extract 'a' from if condition")
call AssertContains(l:result, 'b', "Extract 'b' from if condition")
call AssertContains(l:result, 'c', "Extract 'c' from if condition")
call AssertContains(l:result, 'd', "Extract 'd' from if condition")

" Test: Extract from while condition
let l:line = "while (count < max)"
let l:result = cflow#parser#ExtractConditionVars(l:line)
call AssertContains(l:result, 'count', "Extract 'count' from while condition")
call AssertContains(l:result, 'max', "Extract 'max' from while condition")
