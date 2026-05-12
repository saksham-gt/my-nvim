vim.opt.number = true
vim.opt.relativenumber = true
vim.cmd("syntax on")
vim.opt.mouse='a'
vim.opt.clipboard = 'unnamedplus'
vim.opt.expandtab = true
vim.opt.shiftwidth= 4
vim.opt.tabstop = 4
vim.g.mapleader = ' '
vim.g.maplocalleader=","
vim.opt.termguicolors = true
require("config.lazy")
require("config.keymaps")

-- Autosave: write on insert-leave and on any change in normal mode.
-- Skips unnamed/scratch buffers; silent! swallows read-only errors.
vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
  pattern = "*",
  callback = function()
    if vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) ~= "" then
      vim.cmd("silent! write")
    end
  end,
})



