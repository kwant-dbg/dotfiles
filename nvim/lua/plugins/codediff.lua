vim.pack.add({
  {
    src = 'https://github.com/esmuellert/codediff.nvim',
  },
})

require('codediff').setup()

vim.keymap.set('n', '<leader>gd', '<cmd>CodeDiff<CR>', {
  desc = 'Review Git changes',
})
