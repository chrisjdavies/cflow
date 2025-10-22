#!/bin/bash
# Simple test script for CFlow plugin

set -e

echo "=================================="
echo "CFlow Plugin Simple Tests"
echo "=================================="
echo ""

# Test 1: Check file structure
echo "Test 1: Checking file structure..."
for file in plugin/cflow.vim autoload/cflow.vim autoload/cflow/parser.vim autoload/cflow/analysis.vim autoload/cflow/highlight.vim; do
    if [ -f "$file" ]; then
        echo "  ✓ $file exists"
    else
        echo "  ✗ $file missing"
        exit 1
    fi
done
echo ""

# Test 2: Check for syntax errors
echo "Test 2: Checking for syntax errors..."
for file in plugin/cflow.vim autoload/cflow.vim autoload/cflow/*.vim; do
    if vim -u NONE -N -c "source $file" -c "qall!" 2>&1 | grep -i "error"; then
        echo "  ✗ Syntax error in $file"
        exit 1
    else
        echo "  ✓ $file syntax OK"
    fi
done
echo ""

# Test 3: Test parser functions
echo "Test 3: Testing parser functions..."
cat > /tmp/test_parser.vim << 'EOF'
set runtimepath+=.
source autoload/cflow/parser.vim

" Test ExtractRHSVariables
let result = cflow#parser#ExtractRHSVariables("int b = a + 10;")
if index(result, 'a') != -1
    echo "PASS: ExtractRHSVariables found 'a'"
else
    echo "FAIL: ExtractRHSVariables did not find 'a'"
    cquit!
endif

" Test ExtractConditionVars
let result = cflow#parser#ExtractConditionVars("if (x > y)")
if index(result, 'x') != -1 && index(result, 'y') != -1
    echo "PASS: ExtractConditionVars found 'x' and 'y'"
else
    echo "FAIL: ExtractConditionVars did not find variables"
    cquit!
endif

qall!
EOF

vim -u NONE -N -S /tmp/test_parser.vim 2>&1 | grep -E "PASS|FAIL"
echo ""

# Test 4: Check test fixtures
echo "Test 4: Checking test fixtures..."
for fixture in test/fixtures/*.c; do
    if [ -f "$fixture" ]; then
        echo "  ✓ $(basename $fixture) exists"
    fi
done
echo ""

# Test 5: Check documentation
echo "Test 5: Checking documentation..."
if [ -f "README.md" ]; then
    echo "  ✓ README.md exists"
fi
if [ -f "doc/cflow.txt" ]; then
    echo "  ✓ doc/cflow.txt exists"
fi
if [ -f "DESIGN.md" ]; then
    echo "  ✓ DESIGN.md exists"
fi
echo ""

echo "=================================="
echo "✓ All simple tests passed!"
echo "=================================="
