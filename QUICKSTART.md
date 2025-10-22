# CFlow Quick Start Guide

Get started with CFlow in 5 minutes!

## Installation

### Using vim-plug

Add to your `.vimrc`:

```vim
Plug 'username/cflow'
```

Then run `:PlugInstall`.

## Basic Usage

### 1. Open a C file

```bash
vim demo.c
```

### 2. Navigate to a variable

Move your cursor to any variable you want to understand.

### 3. Focus on it

Press `<leader>cf` (usually `\cf`)

Or run the command:
```vim
:CFlowFocus
```

### 4. See the magic!

- Lines that affect or are affected by your variable stay visible
- Unrelated code is dimmed
- The variable itself is highlighted

### 5. Clear when done

Press `<leader>cc` or run:
```vim
:CFlowClear
```

## Example

Try it with the included demo file:

```bash
vim demo.c
```

1. Go to line 17: `int final = sum * 3;`
2. Put cursor on `sum`
3. Press `<leader>cf`
4. Watch lines with `product` and `unrelated` dim out
5. Lines with `sum`, `i`, and the loop stay visible

## Commands

| Command | What it does |
|---------|-------------|
| `:CFlowFocus` | Focus on variable under cursor |
| `:CFlowClear` | Clear dimming |
| `:CFlowToggle` | Toggle focus on/off |
| `:CFlowStatus` | Show current status |

## Default Keys

| Key | Action |
|-----|--------|
| `<leader>cf` | Focus |
| `<leader>cc` | Clear |
| `<leader>ct` | Toggle |

## Configuration

Add to your `.vimrc`:

```vim
" How much to dim irrelevant code (0-100)
let g:cflow_dim_amount = 60

" What to analyze: 'function' or 'file'
let g:cflow_scope = 'function'

" Show backward, forward, or both
let g:cflow_direction = 'both'
```

## Tips

1. **Start small**: Try it on simple functions first
2. **Use in debugging**: Focus on variables to understand data flow
3. **Understanding code**: Quickly see what affects what
4. **Clear often**: Press `<leader>cc` to reset and try another variable

## Troubleshooting

### Colors not showing up

Make sure your vim supports colors:
```vim
:set termguicolors
```

### Nothing happens

1. Check you're editing a C file: `:set filetype=c`
2. Check plugin is loaded: `:CFlowStatus`
3. Make sure cursor is on a valid variable

### Too slow

Limit the scope:
```vim
let g:cflow_scope = 'function'  " analyze only current function
```

## Next Steps

- Read the [full README](README.md) for details
- Check out [DESIGN.md](DESIGN.md) to understand how it works
- Run tests: `./test/simple_test.sh`
- Read vim help: `:help cflow`

## Questions?

- GitHub Issues: [Report a bug or request a feature]
- Read the docs: `doc/cflow.txt`

Happy coding! 🎉
