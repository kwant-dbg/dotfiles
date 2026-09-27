  -- Pick up changes made outside nvim (e.g. in another tmux pane) as soon as
  -- focus returns, since `autoread` alone only checks on some events.
  vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter' }, {
    pattern = '*',
    command = 'checktime',
  })

  local indentation = vim.api.nvim_create_augroup('user_indentation', {
    clear = true,
  })

  -- Python convention: four spaces.
  vim.api.nvim_create_autocmd('FileType', {
    group = indentation,
    pattern = 'python',
    callback = function(event)
      vim.bo[event.buf].expandtab = true
      vim.bo[event.buf].tabstop = 4
      vim.bo[event.buf].shiftwidth = 4
      vim.bo[event.buf].softtabstop = 4
    end,
  })

  -- C-family convention: four spaces, never literal tab characters.
  vim.api.nvim_create_autocmd('FileType', {
    group = indentation,
    pattern = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
    callback = function(event)
      vim.bo[event.buf].expandtab = true
      vim.bo[event.buf].tabstop = 4
      vim.bo[event.buf].shiftwidth = 4
      vim.bo[event.buf].softtabstop = 4
    end,
  })

  -- Go source uses tabs; gofmt controls the final output.
  vim.api.nvim_create_autocmd('FileType', {
    group = indentation,
    pattern = { 'go', 'gomod', 'gowork' },
    callback = function(event)
      vim.bo[event.buf].expandtab = false
      vim.bo[event.buf].tabstop = 4
      vim.bo[event.buf].shiftwidth = 4
      vim.bo[event.buf].softtabstop = 0
    end,
  })
