  vim.pack.add({
    {
      src = 'https://github.com/nvim-mini/mini.surround',
      version = 'stable',
    },
    {
      src = 'https://github.com/nvim-mini/mini.pairs',
      version = 'stable',
    },
  })

  require('mini.surround').setup({
    mappings = {
      add = 'gsa',
      delete = 'gsd',
      replace = 'gsr',
      find = 'gsf',
      find_left = 'gsF',
      highlight = 'gsh',

      suffix_last = 'l',
      suffix_next = 'n',
    },

    search_method = 'cover_or_next',
  })

  require('mini.pairs').setup()
