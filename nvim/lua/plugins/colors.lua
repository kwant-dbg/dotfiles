vim.pack.add({
  {
    src = 'https://github.com/mellow-theme/mellow.nvim',
  },
})

vim.o.termguicolors = true

-- Lift Mellow's near-black foundation for gentler contrast while keeping its
-- syntax and accent colors intact.
local dark = require('mellow.colors').dark
dark.bg = '#1c1c1e'
dark.bg_dark = '#19191b'
dark.gray00 = '#202023'
dark.gray01 = '#252528'
dark.gray02 = '#303034'

vim.cmd.colorscheme('mellow')

-- Keep diff backgrounds subtle so syntax colors stay readable.
vim.api.nvim_set_hl(0, 'DiffAdd', { bg = '#26382d' })
vim.api.nvim_set_hl(0, 'DiffChange', { bg = '#3a342b' })
vim.api.nvim_set_hl(0, 'DiffDelete', { bg = '#3e292d' })
vim.api.nvim_set_hl(0, 'DiffText', { bg = '#4b4032' })
