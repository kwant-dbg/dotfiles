vim.pack.add({
  {
    src = 'https://github.com/folke/todo-comments.nvim',
  },
})

local mellow = require('mellow.colors')[vim.o.background]

require('todo-comments').setup({
  signs = false,
  merge_keywords = false,
  keywords = {
    ALERT = {
      icon = '! ',
      color = 'alert',
      alt = { '!' },
    },
    QUESTION = {
      icon = '? ',
      color = 'question',
      alt = { '?' },
    },
    HIGHLIGHT = {
      icon = '^ ',
      color = 'highlight',
      alt = { '^' },
    },
    SECTION = {
      icon = '# ',
      color = 'section',
      alt = { '#' },
    },
  },
  highlight = {
    multiline = true,
    before = '',
    keyword = 'fg',
    after = 'fg',
    pattern = [[^\W*([!?#^])\s+]],
    comments_only = true,
  },
  colors = {
    alert = { mellow.red },
    question = { mellow.blue },
    highlight = { mellow.yellow },
    section = { mellow.magenta },
  },
  search = {
    pattern = [[^\W*([!?#^])\s+]],
  },
})

vim.keymap.set('n', ']t', function()
  require('todo-comments').jump_next()
end, {
  desc = 'Next colorful comment',
})

vim.keymap.set('n', '[t', function()
  require('todo-comments').jump_prev()
end, {
  desc = 'Previous colorful comment',
})
