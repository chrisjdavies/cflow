/* Test fixture: simple data flow */

int simple_function() {
    int a = 5;           // line 4
    int b = a + 10;      // line 5 - depends on a
    int c = b * 2;       // line 6 - depends on b
    int d = 100;         // line 7 - independent
    int e = d + 50;      // line 8 - depends on d
    int result = c + 3;  // line 9 - depends on c
    return result;       // line 10 - depends on result
}

/* Expected behavior:
 * When focusing on 'c' at line 9:
 * - Backward slice should include: lines 4, 5, 6, 9 (a -> b -> c -> result)
 * - Line 7 and 8 should be dimmed (independent variable d and e)
 */
