vim.g.nvim_startup_time = vim.uv.hrtime()

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('config.options')
require('config.autocmds')
require('config.keymaps')
require('plugins.completion')
require('config.lsp')
require('plugins')
