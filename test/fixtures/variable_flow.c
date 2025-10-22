/* Test fixture: Variable flow tracking
 * This tests that when we focus on a variable, we also follow
 * derived variables through assignments and function calls.
 */

#include <stdio.h>

int foo(int x) {
    return x * 2;
}

int test_variable_flow(int ep) {
    /* Focus on 'ep' - we should follow all derived variables */

    int a = ep + 5;        /* line 14 - derives from ep, should be visible */

    int cp = foo(ep);      /* line 16 - derives from ep via function call */

    int result = cp * 2;   /* line 18 - uses cp, should be visible because cp derives from ep */

    int unrelated = 100;   /* line 20 - independent, should be DIMMED */

    int final = result + a; /* line 22 - uses result and a, both derive from ep */

    return final;          /* line 24 - depends on final */
}

/* Expected behavior when focusing on 'ep' at line 12:
 *
 * VISIBLE (relevant to ep):
 * - Line 14: a = ep + 5       (directly uses ep)
 * - Line 16: cp = foo(ep)     (directly uses ep)
 * - Line 18: result = cp * 2  (uses cp, which derives from ep)
 * - Line 22: final = result + a (uses result and a, both derive from ep)
 * - Line 24: return final     (uses final)
 *
 * DIMMED (not related to ep):
 * - Line 20: unrelated = 100  (independent variable)
 *
 * This is FORWARD SLICING - following what ep influences
 */
