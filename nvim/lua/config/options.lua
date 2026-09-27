vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.breakindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 1000
vim.opt.completeopt = { "menu", "menuone", "noselect" }
--
-- Default for Lua, YAML, Terraform, and HCL.
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.smartindent = true

-- Use the macOS system clipboard.
vim.opt.clipboard = "unnamedplus"

-- Reload files changed on disk (e.g. by another tmux pane) when focus returns.
vim.opt.autoread = true

-- Show the current file in the terminal/tmux window title.
vim.opt.title = true
vim.opt.titlestring = "%t"

-- ── Interface ────────────────────────────────────────────────────────

-- Keep context visible while scrolling.
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

-- Highlight the cursor's current line.
vim.opt.cursorline = true

-- Preview substitutions while typing.
vim.opt.inccommand = "split"

-- Ask before abandoning unsaved changes.
vim.opt.confirm = true

-- Indentation guides are displayed by Snacks.
vim.opt.list = false

-- Source code generally should not wrap.
vim.opt.wrap = false

-- Use one global statusline at the very bottom.
vim.opt.laststatus = 3

-- Hide the command line until it is actively being used.
vim.opt.cmdheight = 0

-- Give floating windows a consistent edge.
vim.opt.winborder = 'rounded'
