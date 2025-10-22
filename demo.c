/* Demo file to test CFlow plugin */

#include <stdio.h>

int calculate_sum(int n) {
    int sum = 0;           /* line 6 */
    int product = 1;       /* line 7 - independent */
    int i;                 /* line 8 */

    for (i = 0; i < n; i++) {  /* line 10 */
        sum += i;          /* line 11 - modifies sum */
        product *= 2;      /* line 12 - modifies product */
    }

    int unrelated = 999;   /* line 15 - independent */

    int final = sum * 3;   /* line 17 - depends on sum */
    return final;          /* line 18 - depends on final */
}

int main() {
    int x = 5;
    int y = 10;
    int z = x + y;
    int result = calculate_sum(z);
    printf("Result: %d\n", result);
    return 0;
}

/* Instructions:
 * 1. Open this file in vim
 * 2. Go to line 17 (int final = sum * 3;)
 * 3. Place cursor on 'sum'
 * 4. Press <leader>cf (or :CFlowFocus)
 * 5. Lines 7, 12, and 15 should be dimmed (product and unrelated)
 * 6. Lines 6, 8, 10, 11, 17, 18 should remain visible
 */
