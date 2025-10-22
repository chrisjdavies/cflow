/* Test fixture: complex data flow with loops */

int complex_function(int n) {
    int sum = 0;           // line 4
    int product = 1;       // line 5
    int i;                 // line 6

    for (i = 0; i < n; i++) {  // line 8 - uses i and n
        sum += i;          // line 9 - modifies sum, uses i
        product *= 2;      // line 10 - modifies product
    }

    int independent = 999; // line 13 - not related to sum

    int final = sum * 3;   // line 15 - depends on sum
    return final;          // line 16 - depends on final
}

/* Expected behavior:
 * When focusing on 'sum' at line 15:
 * - Should include: lines 4, 6, 8, 9, 15, 16
 * - Should include loop: line 8 (for statement)
 * - Should dim: lines 5, 10, 13 (product and independent)
 */
