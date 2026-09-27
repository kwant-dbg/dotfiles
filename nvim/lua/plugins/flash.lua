vim.pack.add({
  {
    src = 'https://github.com/folke/flash.nvim',
    version = 'v2.1.0',
  },
})

require('flash').setup({
  modes = {
    char = {
      enabled = false,
    },
  },
})

vim.keymap.set({ 'n', 'x', 'o' }, 's', function()
  require('flash').jump()
end, {
  desc = 'Flash jump',
})
