/* DEMO: Variable Flow Tracking Fix
 *
 * This demonstrates the fix for following derived variables.
 *
 * BEFORE THE FIX:
 * ===============
 * When focusing on 'ep' at line 10:
 *   Line 11: cp = foo(ep);     [VISIBLE] ✓
 *   Line 12: result = cp * 2;  [DIMMED]  ✗ WRONG! cp is not followed
 *   Line 13: unrelated = 100;  [DIMMED]  ✓
 *
 * AFTER THE FIX:
 * ==============
 * When focusing on 'ep' at line 10:
 *   Line 11: cp = foo(ep);     [VISIBLE] ✓ cp derives from ep
 *   Line 12: result = cp * 2;  [VISIBLE] ✓ result uses cp!
 *   Line 13: unrelated = 100;  [DIMMED]  ✓ independent
 *
 * The fix ensures that variable flow is tracked transitively:
 *   ep → cp → result
 *
 * All variables in this chain stay visible!
 */

#include <stdio.h>

int foo(int x) {
    return x * 2;
}

int test_function(int ep) {
    // Focus on 'ep' here ↓
    // (place cursor on 'ep' and press \cf)

    int cp = foo(ep);      // cp is derived from ep
    int result = cp * 2;   // result uses cp (which came from ep!)
    int unrelated = 100;   // independent - should be dimmed

    printf("Result: %d\n", result);
    return result;
}

int main() {
    int value = test_function(5);
    return 0;
}

/*
 * INSTRUCTIONS:
 * =============
 * 1. Open this file in vim
 * 2. Go to line 30 (int test_function(int ep) {)
 * 3. Place cursor on 'ep'
 * 4. Press \cf (or :CFlowFocus)
 *
 * EXPECTED RESULT:
 * ================
 * Lines 32-33: cp and result stay VISIBLE (they derive from ep)
 * Line 34: unrelated is DIMMED (independent)
 *
 * This is the correct behavior - the fix ensures that variables
 * derived through assignments are followed!
 *
 * Data flow: ep → cp → result → printf → return
 * All steps in the flow remain visible ✓
 */
