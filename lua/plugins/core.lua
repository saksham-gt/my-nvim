return {

{
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("nvim-tree").setup({
      view = {
        width = 30,
        relativenumber = true,
      },
      renderer = {
        indent_markers = { enable = true },
      },
      filters = {
        dotfiles = false,
      },
    })

    -- Keymap
    vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>")
  end,
},
  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    keys = {
      
    { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Search Document Symbols" },
    { "<leader>fw", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", desc = "Search Workspace Symbols" },
    },
    opts = {
        extensions = {
            
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = "smart_case"
      }
        }
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup()

      -- enable fzf native
      telescope.load_extension("fzf")

      local builtin = require("telescope.builtin")

      -- Keymaps
      vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
      vim.keymap.set("n", "<leader>fb", builtin.buffers, {})

    end,
  },

  -- Lualine
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("lualine").setup({
        options = {
            theme = "catppuccin",
        }
      })
    end,
  },

}
