# C-Flow: Code Focus Plugin for Vim

## Overview

C-Flow is a vim plugin that implements code focus functionality for C code, inspired by [flowistry](https://github.com/willcrichton/flowistry). It allows users to select a variable or expression and automatically dims unrelated code, helping developers focus on relevant code paths.

## How Flowistry Works

Flowistry analyzes information flow in Rust programs:
1. User clicks/selects a variable or expression
2. Tool performs dataflow analysis to find:
   - **Backward slice**: Code that influences the selection
   - **Forward slice**: Code influenced by the selection
3. All other code is dimmed/faded
4. Uses Rust compiler's MIR (Mid-level Intermediate Representation) for analysis

## Our Approach for C + Vim

Since we can't use the C compiler's internals and need to work with unparsable code, we'll use a hybrid approach:

### Tool Selection: Tree-sitter vs Cscope/Ctags

**Why Tree-sitter is preferred:**
- **Robust parsing**: Works with incomplete/invalid code
- **Incremental parsing**: Fast updates
- **AST access**: Can perform data flow analysis
- **No compilation needed**: Works on broken code
- **Better accuracy**: Understands C syntax deeply

**Cscope/Ctags limitations:**
- Require relatively complete code
- Limited to symbol lookup (no data flow)
- Can't handle incomplete functions well
- No AST access for analysis

**Decision: Use tree-sitter with cscope/ctags fallback**

### Architecture

```
┌─────────────────────────────────────────────────────┐
│                  User Interface                     │
│  (Vim commands: CFlowFocus, CFlowClear, etc.)      │
└─────────────────┬───────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────┐
│              Analysis Engine                        │
│  - Parse C code (tree-sitter)                      │
│  - Build control flow graph                        │
│  - Perform data flow analysis                      │
│  - Generate backward/forward slices                │
└─────────────────┬───────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────┐
│            Visualization Layer                      │
│  - Calculate line ranges to dim                    │
│  - Apply syntax highlighting/concealment           │
│  - Manage highlight groups                         │
└─────────────────────────────────────────────────────┘
```

## Implementation Plan

### Phase 1: Core Infrastructure

1. **Plugin Structure**
   ```
   cflow/
   ├── plugin/cflow.vim          # Plugin entry point
   ├── autoload/cflow.vim        # Main logic
   ├── autoload/cflow/
   │   ├── parser.vim            # Tree-sitter integration
   │   ├── analysis.vim          # Data flow analysis
   │   └── highlight.vim         # Visualization
   ├── queries/
   │   └── c/                    # Tree-sitter queries
   │       ├── variables.scm     # Variable queries
   │       └── functions.scm     # Function queries
   ├── test/
   │   ├── test_runner.vim       # Test framework
   │   ├── test_parser.vim       # Parser tests
   │   ├── test_analysis.vim     # Analysis tests
   │   └── fixtures/             # Test C files
   └── doc/cflow.txt             # Documentation
   ```

2. **Vim Integration**
   - Commands: `:CFlowFocus`, `:CFlowClear`, `:CFlowToggle`
   - Mappings: `<leader>cf` to focus on word under cursor
   - Auto-commands: Clear on buffer changes

3. **Tree-sitter Integration**
   - Use `vim-treesitter` or direct libtree-sitter bindings
   - For classic vim: Use external tree-sitter CLI or Python/Lua bridge
   - Alternative: Implement lightweight parser in vimscript

### Phase 2: Analysis Engine

**Strategy: Simplified Data Flow Analysis**

Since full data flow analysis is complex, we'll implement a practical approximation:

1. **Variable Dependency Tracking**
   ```c
   int a = 5;           // Definition
   int b = a + 10;      // b depends on a
   int c = b * 2;       // c depends on b (transitively on a)
   printf("%d", c);     // Uses c
   ```

2. **Analysis Components**

   **a) Symbol Resolution**
   - Find all references to selected variable
   - Track variable assignments and uses
   - Handle scope (local, global, function parameters)

   **b) Backward Slice (What influences this?)**
   - Find all assignments to the variable
   - Track variables used in those assignments
   - Recursively track dependencies
   - Include control flow (if/while conditions)

   **c) Forward Slice (What does this influence?)**
   - Find all uses of the variable
   - Track variables assigned from this variable
   - Recursively track dependents
   - Include control flow guards

3. **Control Flow Handling**
   - Track conditionals that guard code
   - Include loop conditions that use the variable
   - Handle function calls (parameters, return values)

4. **Scope Management**
   - Respect variable scope (local, global, static)
   - Handle shadowing correctly
   - Track function boundaries

### Phase 3: Visualization

**Approach: Use vim's syntax highlighting system**

1. **Dimming Mechanism**
   ```vim
   " Create highlight group for dimmed code
   highlight CFlowDimmed guifg=#808080 ctermfg=gray

   " Apply to line ranges
   call matchaddpos('CFlowDimmed', [[10, 1], [11, 1], [12, 1]])
   ```

2. **Highlighting Strategy**
   - Keep focused code at normal brightness
   - Dim irrelevant code by 60-70%
   - Optionally highlight the selected variable itself
   - Use different colors for backward/forward slices

3. **Performance Considerations**
   - Cache parse trees
   - Incremental updates on small changes
   - Limit analysis scope (current function, current file)
   - Async analysis for large files (if vim8+)

### Phase 4: Fallback to Cscope/Ctags

If tree-sitter is unavailable:

1. **Cscope Integration**
   - Use `cscope find` to locate symbol references
   - Build simple dependency graph
   - Less accurate but still useful

2. **Ctags Integration**
   - Use tags file for symbol lookup
   - Limited to definitions only
   - Minimal but functional

## Algorithm Details

### Simplified Data Flow Algorithm

```python
def analyze_focus(variable, line, column):
    # 1. Parse the file
    ast = parse_file_with_treesitter(current_buffer)

    # 2. Find the selected variable node
    node = find_node_at_position(ast, line, column)
    variable_name = node.text
    scope = find_enclosing_scope(node)

    # 3. Find all references in scope
    all_refs = find_variable_references(ast, variable_name, scope)

    # 4. Build dependency graph
    dependencies = {}
    for ref in all_refs:
        if is_assignment(ref):
            rhs_vars = extract_variables_from_rhs(ref)
            dependencies[ref] = rhs_vars

    # 5. Backward slice (BFS from selected node)
    backward_slice = set()
    queue = [node]
    while queue:
        current = queue.pop(0)
        backward_slice.add(current)
        # Add all dependencies
        if current in dependencies:
            queue.extend(dependencies[current])

    # 6. Forward slice (reverse dependency graph)
    forward_slice = set()
    queue = [node]
    while queue:
        current = queue.pop(0)
        forward_slice.add(current)
        # Find all nodes that depend on current
        for ref, deps in dependencies.items():
            if current in deps:
                queue.append(ref)

    # 7. Combine slices
    relevant_lines = extract_line_numbers(backward_slice | forward_slice)

    # 8. Add control flow
    relevant_lines |= find_control_flow_guards(relevant_lines, ast)

    # 9. Return lines to keep visible
    return relevant_lines
```

## Testing Strategy

### Test Categories

1. **Unit Tests**
   - Parser correctness
   - Variable extraction
   - Dependency graph building
   - Slice computation

2. **Integration Tests**
   - Full analysis pipeline
   - Vim command execution
   - Highlighting application

3. **Fixture Tests**
   - Various C code patterns
   - Edge cases (macros, pointers, etc.)

### Test Framework

Use a simple vimscript test runner:
```vim
function! RunTests()
    for test_file in glob('test/test_*.vim', 0, 1)
        execute 'source' test_file
    endfor
endfunction
```

### Test Fixtures

Create C files with known dependencies and verify correct slicing:

```c
// fixture1.c - Simple dependencies
int a = 5;
int b = a + 10;    // depends on a
int c = b * 2;     // depends on b
int d = 100;       // independent
printf("%d", c);   // uses c

// When focusing on 'c' at printf line:
// Expected: lines 1, 2, 3, 5 visible; line 4 dimmed
```

## Feature Set

### MVP (Minimum Viable Product)
- [x] Focus on single variable in current function
- [x] Backward slice (show what influences)
- [x] Dim unrelated code
- [x] Work with tree-sitter
- [x] Basic vim commands

### Nice-to-Have
- [ ] Forward slice option
- [ ] Focus on expressions (not just variables)
- [ ] Cross-function analysis
- [ ] Multiple files support
- [ ] Cscope/ctags fallback
- [ ] Configurable dimming levels
- [ ] Highlight path from selection to dependencies

## Challenges and Solutions

### Challenge 1: Tree-sitter in Classic Vim
**Problem**: Vim 8 doesn't have native tree-sitter support (neovim does)

**Solutions**:
1. Use external tree-sitter CLI, parse to JSON, process in vimscript
2. Use Python bindings (if vim has +python3)
3. Implement simplified parser in vimscript for C
4. Recommend neovim for better experience (but still support vim)

**Chosen**: Use Python bindings with fallback to simple regex-based parser

### Challenge 2: Data Flow Analysis Complexity
**Problem**: Full data flow analysis is complex (pointer aliasing, etc.)

**Solution**: Implement practical approximation:
- Track direct assignments and uses
- Handle simple pointers (no complex aliasing)
- Warn users about limitations
- Focus on common cases (90% accuracy is useful)

### Challenge 3: Performance
**Problem**: Analysis might be slow on large files

**Solutions**:
- Scope analysis to current function by default
- Cache parse results
- Incremental updates
- Async analysis (vim8+ or neovim)
- User can expand scope with command flag

### Challenge 4: Visualization
**Problem**: Dimming might interfere with existing syntax highlighting

**Solutions**:
- Use high-priority highlight groups
- Preserve syntax colors, just reduce brightness
- Allow users to configure dim amount
- Option to use concealment instead of dimming

## Configuration Options

```vim
" Enable/disable plugin
let g:cflow_enabled = 1

" Dim percentage (0-100)
let g:cflow_dim_amount = 60

" Analysis scope: 'function', 'file', 'project'
let g:cflow_scope = 'function'

" Use tree-sitter, cscope, or ctags
let g:cflow_backend = 'treesitter'  " or 'cscope' or 'ctags'

" Show forward slice, backward slice, or both
let g:cflow_direction = 'both'  " or 'forward' or 'backward'

" Highlight focused variable
let g:cflow_highlight_variable = 1

" Auto-clear on cursor move
let g:cflow_auto_clear = 0
```

## Success Criteria

1. **Functionality**: User can select variable, see relevant code, dim irrelevant
2. **Accuracy**: >80% correct in common cases
3. **Performance**: <500ms analysis for typical function
4. **Usability**: Simple commands, clear visual feedback
5. **Reliability**: Works on incomplete code, doesn't crash
6. **Compatibility**: Works on vim 8.0+

## Timeline Estimate

- **Phase 1** (Infrastructure): 4-6 hours
- **Phase 2** (Analysis): 8-10 hours
- **Phase 3** (Visualization): 2-3 hours
- **Phase 4** (Testing): 4-5 hours
- **Total**: 18-24 hours

## References

- Flowistry: https://github.com/willcrichton/flowistry
- Tree-sitter: https://tree-sitter.github.io/tree-sitter/
- Program Slicing: https://en.wikipedia.org/wiki/Program_slicing
- Vim Syntax Highlighting: `:help syntax`
- Vim Matching: `:help matchaddpos()`
