-- Options
vim.opt.number = true
vim.opt.wrap = false
vim.opt.cursorline = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.clipboard = "unnamedplus"
vim.opt.path:append("**")
vim.opt.wildmenu = true

-- Colorscheme
vim.cmd.colorscheme("catppuccin")

-- Key remaps: swap 0, $, ^ across normal, visual, and operator-pending modes
local modes = { "n", "v", "o" }
vim.keymap.set(modes, "0", "$")
vim.keymap.set(modes, "$", "^")
vim.keymap.set(modes, "!", "0")
vim.keymap.set(modes, "^", "!")

vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
  },
}

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.highlight.on_yank({higroup="Visual", timeout=150}) end
})
