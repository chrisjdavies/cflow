/* Test fixture: control flow */

int control_flow_function(int x) {
    int result = 0;        // line 4
    int multiplier = 2;    // line 5

    if (x > 10) {          // line 7 - condition uses x
        result = x * multiplier;  // line 8 - depends on x and multiplier
    } else {
        result = x + 5;    // line 10 - depends on x
    }

    int unrelated = 42;    // line 13 - independent

    return result;         // line 15 - depends on result
}

/* Expected behavior:
 * When focusing on 'result' at line 15:
 * - Should include: lines 4, 7, 8, 10, 15
 * - Should include control flow: line 7 (if statement)
 * - Should include multiplier: line 5, 8
 * - Should dim: line 13 (unrelated)
 */
