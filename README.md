# my-nvim

Personal Neovim configuration. Drop the contents of this repo into `~/.config/nvim/` and launch `nvim` — `lazy.nvim` bootstraps itself and installs every plugin on first run.

```bash
git clone <this-repo> ~/.config/nvim
nvim   # first launch installs everything; restart once it finishes
```

Requires Neovim **0.11+** (uses the new `vim.lsp.config` / `vim.lsp.enable` API).

---

## Layout

```
~/.config/nvim/
├── init.lua                 # entry point: options, leaders, autosave, requires
├── lazy-lock.json           # pinned plugin commits (commit this!)
└── lua/
    ├── config/
    │   ├── lazy.lua         # bootstraps lazy.nvim, loads plugin specs
    │   └── keymaps.lua      # global keymaps not tied to any plugin
    └── plugins/
        ├── colors.lua       # colorscheme
        ├── core.lua         # editor UX: file tree, fuzzy finder, statusline
        └── pyconfigs.lua    # everything Python: LSP, completion, format, venv
```

---

## Editor options (`init.lua`)

| Setting | Value | Why |
|---|---|---|
| `number` + `relativenumber` | on | Hybrid line numbers — current line absolute, others relative for easy `5j`/`12k`. |
| `mouse = 'a'` | all modes | Mouse works for selection, scrolling, window resizing. |
| `clipboard = 'unnamedplus'` | system clipboard | `y`/`p` use the OS clipboard — paste works across apps. |
| `expandtab`, `shiftwidth=4`, `tabstop=4` | spaces, 4-wide | Python convention; works fine for most other langs. |
| `termguicolors` | on | Required for true-color themes like Catppuccin. |

### Leader keys

- `<leader>` = **Space**
- `<localleader>` = **`\`** (backslash)

> **Note**: `init.lua` sets localleader to `,` but `lua/config/lazy.lua` overrides it to `\` later in startup. The effective value is `\`. If you want `,`, remove the `vim.g.maplocalleader = "\\"` line in `lua/config/lazy.lua`.

### Autosave

Buffer is written automatically on `InsertLeave` and `TextChanged` (normal-mode edits like `dd`, `p`). Skips scratch/unnamed buffers. Defined inline in `init.lua`.

---

## Theme

**[catppuccin/nvim](https://github.com/catppuccin/nvim)** — flavor: `mocha` (dark, warm).

Other flavors available: `latte` (light), `frappe`, `macchiato`. Change in `lua/plugins/colors.lua`.

`lualine` is themed to match (`theme = "catppuccin"` in `core.lua`).

---

## Plugins

Managed by **[folke/lazy.nvim](https://github.com/folke/lazy.nvim)** (auto-bootstrapped from `lua/config/lazy.lua`). `checker.enabled = true` means lazy will check for plugin updates in the background.

### Editor & navigation (`lua/plugins/core.lua`)

| Plugin | Purpose |
|---|---|
| **[nvim-tree/nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua)** | File explorer sidebar. 30 cols wide, shows dotfiles, indent markers on. |
| **[nvim-tree/nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons)** | File-type icons (needs a Nerd Font installed in your terminal). |
| **[nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)** | Fuzzy finder for files, buffers, symbols, grep results. |
| **[nvim-telescope/telescope-fzf-native.nvim](https://github.com/nvim-telescope/telescope-fzf-native.nvim)** | Native C sorter for telescope — much faster than the Lua default. Requires `make`. |
| **[nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim)** | Lua utility lib (telescope dependency). |
| **[nvim-lualine/lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)** | Statusline (mode, file, git branch, location). |

### Colorscheme (`lua/plugins/colors.lua`)

| Plugin | Purpose |
|---|---|
| **[catppuccin/nvim](https://github.com/catppuccin/nvim)** | Theme (mocha flavor). Loaded with `priority = 1000` so it applies before any other plugin renders. |

### Python development (`lua/plugins/pyconfigs.lua`)

| Plugin | Purpose |
|---|---|
| **[neovim/nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)** | Default configs for language servers. Wires `pyright` (types/completions) and `ruff` (lint). |
| **[williamboman/mason.nvim](https://github.com/williamboman/mason.nvim)** | Installs LSP servers, formatters, linters into nvim's data dir — no system pkg manager needed. |
| **[williamboman/mason-lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim)** | Bridge between mason and lspconfig. `ensure_installed = { "pyright", "ruff" }` auto-installs them. |
| **[hrsh7th/nvim-cmp](https://github.com/hrsh7th/nvim-cmp)** | Completion engine (UI). Tab-triggered (`autocomplete = false`). |
| **[hrsh7th/cmp-nvim-lsp](https://github.com/hrsh7th/cmp-nvim-lsp)** | cmp source: LSP semantic completions (functions, classes, library symbols). |
| **[hrsh7th/cmp-buffer](https://github.com/hrsh7th/cmp-buffer)** | cmp source: words from any open buffer. Falls back when LSP has nothing. |
| **[hrsh7th/cmp-path](https://github.com/hrsh7th/cmp-path)** | cmp source: filesystem paths (typing `./` or `/` triggers it). |
| **[L3MON4D3/LuaSnip](https://github.com/L3MON4D3/LuaSnip)** | Snippet engine. |
| **[saadparwaiz1/cmp_luasnip](https://github.com/saadparwaiz1/cmp_luasnip)** | cmp source: LuaSnip snippets. |
| **[nvim-treesitter/nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)** | AST-based syntax highlighting for `c`, `lua`, `vim`, `vimdoc`, `query`, `python`, `javascript`. Also powers incremental selection (`<C-n>` / `<C-m>`). |
| **[stevearc/conform.nvim](https://github.com/stevearc/conform.nvim)** | Formatter runner. Python: `ruff_organize_imports` then `black`. |
| **[linux-cultist/venv-selector.nvim](https://github.com/linux-cultist/venv-selector.nvim)** | Pick a Python virtualenv at runtime; restarts the LSP against it. |

---

## Python: how completions actually work

`pyright` reads `site-packages/` of whatever interpreter you point it at. So library completions (`pd.<Tab>` showing pandas API) only work if pyright is using the venv where you `pip install`'d that library.

The config auto-detects the interpreter in this order (see `resolve_python()` in `pyconfigs.lua`):

1. `$VIRTUAL_ENV` — if you `source .venv/bin/activate` before launching nvim.
2. `./.venv/bin/python` → `./venv/bin/python` → `./.virtualenv/bin/python` — project-local.
3. `$CONDA_PREFIX/bin/python` — active conda env.
4. System `python3` — fallback.

**Quick checks**:

- `:PyInfo` — prints which interpreter pyright is using and where its site-packages live.
- `<leader>vs` — interactive venv picker (lists candidates from common paths).

**Setup for a new project**:

```bash
cd your-project
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt   # or whatever you need
nvim some_file.py    # auto-detect picks up .venv/bin/python
```

---

## Keymap reference

### Global (`lua/config/keymaps.lua`)

| Key | Action |
|---|---|
| `jk` (insert mode) | Escape to normal mode. |
| `<leader>tt` | Open terminal in horizontal split. |

### File tree (nvim-tree, `core.lua`)

| Key | Action |
|---|---|
| `<leader>e` | Toggle file tree sidebar. |

### Fuzzy finder (telescope, `core.lua`)

| Key | Action |
|---|---|
| `<leader>ff` | Find files. |
| `<leader>fg` | Live grep across project. |
| `<leader>fb` | Switch buffers. |
| `<leader>fs` | Document symbols (functions/classes in current file). |
| `<leader>fw` | Workspace symbols (across project, requires LSP). |

### LSP (auto-bound on `LspAttach`, `pyconfigs.lua`)

These are active in any buffer where an LSP attaches.

| Key | Action |
|---|---|
| `gd` | Go to definition. |
| `gD` | Go to declaration. |
| `gr` | Find references. |
| `gi` | Go to implementation. |
| `K` | Hover docs. |
| `<leader>rn` | Rename symbol (project-wide). |
| `<leader>ca` | Code actions (quick fixes, refactors). |
| `<leader>ds` | Show diagnostic at cursor in float. |
| `[d` / `]d` | Previous / next diagnostic. |

### Python tools (`pyconfigs.lua`)

| Key | Action |
|---|---|
| `<leader>cf` | Format current buffer (ruff imports + black). |
| `<leader>vs` | Pick Python venv interactively. |
| `:PyInfo` | Print resolved interpreter, version, site-packages. |

### Completion (nvim-cmp, `pyconfigs.lua`)

| Key | Action |
|---|---|
| `<Tab>` | Trigger completion / select next item / expand snippet. |
| `<S-Tab>` | Select previous item / jump back in snippet. |
| `<CR>` | Accept selected completion. |
| `<C-e>` | Abort completion popup. |

### Treesitter incremental selection (`pyconfigs.lua`)

| Key | Action |
|---|---|
| `<C-n>` | Start selection / expand to next AST node. |
| `<C-s>` | Expand to enclosing scope. |
| `<C-m>` | Shrink selection. |

---

## Maintenance

| Command | Purpose |
|---|---|
| `:Lazy` | Plugin manager UI — install, update, sync, profile startup. |
| `:Lazy sync` | Install missing plugins + update existing ones. |
| `:Mason` | Manage LSP servers / formatters installed by mason. |
| `:checkhealth` | Diagnose nvim, plugin, and LSP health. |
| `:TSUpdate` | Update treesitter parsers. |

`lazy-lock.json` pins exact plugin commits — **commit it** so the same versions install on other machines. To bump everything, `:Lazy update` then commit the new lock file.

---

## External dependencies

These need to exist on `$PATH` (or be installed via mason):

- **Neovim ≥ 0.11**
- **git** — lazy.nvim uses it to clone plugins.
- **make** + a C compiler — needed once to build `telescope-fzf-native`.
- **Nerd Font** in your terminal — for nvim-tree / lualine icons. (e.g. JetBrainsMono Nerd Font)
- **Python 3** — for any Python work; `python3 -m venv` for virtualenvs.
- **ripgrep** (`rg`) — telescope live-grep uses it.
- **Node.js** — pyright runs on Node; mason installs it but the system needs it available.
