return {
{ "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim"
  },
  config = function()
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

    -- Find the right Python interpreter for the current project.
    -- Order: $VIRTUAL_ENV (already-activated shell) → project-local .venv/venv
    -- → conda env → system python3. The interpreter's site-packages is what
    -- pyright will scan for library completions, so this is the one knob
    -- that decides whether `import pandas` shows pandas' API or "unresolved".
    local function resolve_python()
      if vim.env.VIRTUAL_ENV then
        return vim.env.VIRTUAL_ENV .. "/bin/python"
      end
      local cwd = vim.fn.getcwd()
      for _, name in ipairs({ ".venv", "venv", ".virtualenv" }) do
        local candidate = cwd .. "/" .. name .. "/bin/python"
        if vim.fn.executable(candidate) == 1 then
          return candidate
        end
      end
      if vim.env.CONDA_PREFIX then
        return vim.env.CONDA_PREFIX .. "/bin/python"
      end
      return vim.fn.exepath("python3")
    end

    require('mason').setup()
    local mason_lspconfig = require 'mason-lspconfig'
    mason_lspconfig.setup {
        ensure_installed = { "pyright", "ruff" }
    }

      -- Pyright: types, autocomplete, go-to-definition.
      -- Hover off because ruff also provides hover; keeps signatures clean.
      vim.lsp.config("pyright", {
        capabilities = capabilities,
        settings = {
          pyright = {
            disableOrganizeImports = true, -- ruff handles imports
          },
          python = {
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "workspace",
              typeCheckingMode = "basic",
            },
            pythonPath = resolve_python(),
          },
        },
      })
      vim.lsp.enable("pyright")

      -- Ruff: lint + import sorting (and optionally formatting).
      vim.lsp.config("ruff", {
        capabilities = capabilities,
        init_options = {
          settings = {
            args = {},
          },
        },
      })
      vim.lsp.enable("ruff")

      -- :PyInfo — shows the interpreter pyright resolved to. If library
      -- imports show "unresolved", run this first; mismatch is the cause 90%
      -- of the time. Switch venvs at runtime with <leader>vs (venv-selector).
      vim.api.nvim_create_user_command("PyInfo", function()
        local py = resolve_python()
        local version = vim.fn.system(py .. " --version"):gsub("\n", "")
        local site = vim.fn.system(py .. " -c 'import site; print(site.getsitepackages()[0])'"):gsub("\n", "")
        vim.notify(
          ("Interpreter: %s\nVersion:     %s\nSite-packages: %s"):format(py, version, site),
          vim.log.levels.INFO
        )
      end, {})

      -- LSP keymaps — applied per-buffer when any LSP attaches.
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local buf = args.buf
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
          end
          map("n", "gd", vim.lsp.buf.definition, "Go to definition")
          map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
          map("n", "gr", vim.lsp.buf.references, "Find references")
          map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
          map("n", "K",  vim.lsp.buf.hover, "Hover docs")
          map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("n", "<leader>ds", vim.diagnostic.open_float, "Show diagnostic")
          map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, "Prev diagnostic")
          map("n", "]d", function() vim.diagnostic.jump({ count =  1 }) end, "Next diagnostic")
        end,
      })
end
},

-- Formatter: black for code, ruff for import sorting.
-- conform.nvim runs CLI formatters as a unified interface.
{ "stevearc/conform.nvim",
  config = function()
    require("conform").setup({
      formatters_by_ft = {
        python = { "ruff_organize_imports", "black" },
      },
      -- TODO: decide whether you want format-on-save (see comment in file)
      format_on_save = nil,
    })
    vim.keymap.set({ "n", "v" }, "<leader>cf", function()
      require("conform").format({ async = true, lsp_format = "fallback" })
    end, { desc = "Format buffer" })
  end,
},

-- Virtualenv switcher: tells pyright/ruff which interpreter to use.
-- Hit <leader>vs to pick the venv for the current project.
{ "linux-cultist/venv-selector.nvim",
  branch = "regexp",
  dependencies = {
    "neovim/nvim-lspconfig",
    "nvim-telescope/telescope.nvim",
  },
  opts = {},
  keys = {
    { "<leader>vs", "<cmd>VenvSelect<cr>", desc = "Select Python venv" },
  },
},


{ "nvim-treesitter/nvim-treesitter", version = false,
  build = function()
    require("nvim-treesitter.install").update({ with_sync = true })
  end,
  config = function()
    require("nvim-treesitter.config").setup({
      ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "python", "javascript" },
      auto_install = false,
      highlight = { enable = true, additional_vim_regex_highlighting = false },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-n>",
          node_incremental = "<C-n>",
          scope_incremental = "<C-s>",
          node_decremental = "<C-m>",
        }
      }
    })
  end
},
{ "hrsh7th/nvim-cmp",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip"
  },
  config = function()
    local has_words_before = function()
      unpack = unpack or table.unpack
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
    end

    local cmp = require('cmp')
    local luasnip = require('luasnip')

    cmp.setup({
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end
      },
      completion = {
        autocomplete = false
      },
      mapping = cmp.mapping.preset.insert ({
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<s-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<c-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select=true }),
      }),
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" },
      }, {
        -- Fallback group: only shown if the first group returns nothing,
        -- so LSP semantic matches always rank above raw word matches.
        {
          name = "buffer",
          option = {
            -- Pull words from every loaded buffer, not just the current one.
            get_bufnrs = function()
              local bufs = {}
              for _, win in ipairs(vim.api.nvim_list_wins()) do
                bufs[vim.api.nvim_win_get_buf(win)] = true
              end
              return vim.tbl_keys(bufs)
            end,
          },
        },
        { name = "path" },
      })
    })
  end
},
}
