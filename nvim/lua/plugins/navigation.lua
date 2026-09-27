vim.pack.add({
    {
      src = 'https://github.com/nvim-mini/mini.files',
      version = 'stable',
    },
    {
      src = 'https://github.com/nvim-mini/mini.icons',
      version = 'stable',
    },
  })

  require('mini.icons').setup()

  require('mini.files').setup({
    windows = {
      preview = true,
      width_focus = 30,
      width_preview = 50,
    },
  })

  -- Keep Ghostty/tmux navigation intact. Use Kitty's native panes only
  -- when Neovim is running directly in Kitty.
  if vim.env.KITTY_WINDOW_ID and not vim.env.TMUX then
    vim.pack.add({
      { src = 'https://github.com/smart-splits-nvim/smart-splits.nvim' },
    })
    require('smart-splits').setup({ at_edge = 'stop' })
  end
