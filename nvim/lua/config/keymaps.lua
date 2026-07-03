-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })

vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.keymap.set("t", "<C-h>", "<C-\\><C-n><cmd>TmuxNavigateLeft<cr>")
vim.keymap.set("t", "<C-j>", "<C-\\><C-n><cmd>TmuxNavigateDown<cr>")
vim.keymap.set("t", "<C-k>", "<C-\\><C-n><cmd>TmuxNavigateUp<cr>")
vim.keymap.set("t", "<C-l>", "<C-\\><C-n><cmd>TmuxNavigateRight<cr>")
