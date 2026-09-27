  -- ── Keymaps ──────────────────────────────────────────────────────────

  local map = vim.keymap.set

  -- Familiar from your previous configuration.
  map('i', 'jk', '<Esc>', {
    desc = 'Exit insert mode',
  })

  -- Clear search highlighting.
  map('n', '<Esc>', '<cmd>nohlsearch<CR>', {
    desc = 'Clear search highlighting',
  })

  -- mini.files---

  map('n', '<leader>e', function()
    local path = vim.api.nvim_buf_get_name(0)

    if path == '' then
      path = vim.uv.cwd()
    end

    require('mini.files').open(path)
  end, {
    desc = 'File explorer',
  })

  map('n', '<leader>ff', function()
    Snacks.picker.files()
  end, {
    desc = 'Find files',
  })

  map('n', '<leader>fg', function()
    Snacks.picker.grep()
  end, {
    desc = 'Live grep',
  })

  map('n', '<leader>fb', function()
    Snacks.picker.buffers()
  end, {
    desc = 'Find buffers',
  })

  map('n', '<leader>fh', function()
    Snacks.picker.help()
  end, {
    desc = 'Search help',
  })
---mini ends---

  -- Create splits.
  map('n', '<leader>-', '<cmd>split<CR>', {
    desc = 'Split below',
  })

  map('n', '<leader>|', '<cmd>vsplit<CR>', {
    desc = 'Split right',
  })

   -- Navigate between open buffers.
  map('n', '<S-h>', '<cmd>bprevious<CR>', {
    desc = 'Previous buffer',
  })

  map('n', '<S-l>', '<cmd>bnext<CR>', {
    desc = 'Next buffer',
  })

  -- Close the current buffer.
  map('n', '<leader>bd', '<cmd>bdelete<CR>', {
    desc = 'Delete buffer',
  })


  -- ── Quickfix ─────────────────────────────────────────────────────────

  map('n', ']q', '<cmd>cnext<CR>', {
    desc = 'Next quickfix result',
  })

  map('n', '[q', '<cmd>cprevious<CR>', {
    desc = 'Previous quickfix result',
  })

  map('n', '<leader>qo', '<cmd>copen<CR>', {
    desc = 'Open quickfix list',
  })

  map('n', '<leader>qc', '<cmd>cclose<CR>', {
    desc = 'Close quickfix list',
  })

  local tmux_directions = {
    h = 'L',
    j = 'D',
    k = 'U',
    l = 'R',
  }

  local function navigate_window_or_tmux(direction)
    if vim.env.KITTY_WINDOW_ID and not vim.env.TMUX then
      local move = {
        h = 'move_cursor_left',
        j = 'move_cursor_down',
        k = 'move_cursor_up',
        l = 'move_cursor_right',
      }
      require('smart-splits')[move[direction]]()
      return
    end

    local original_window = vim.api.nvim_get_current_win()

    vim.cmd.wincmd(direction)

    -- If Neovim moved to another split, we are done.
    if vim.api.nvim_get_current_win() ~= original_window then
      return
    end

    -- At a Neovim edge, move to the adjacent tmux pane.
    if vim.env.TMUX and vim.fn.executable('tmux') == 1 then
      vim.system({
        'tmux',
        'select-pane',
        '-' .. tmux_directions[direction],
      })
    end
  end

  map('n', '<C-h>', function()
    navigate_window_or_tmux('h')
  end, {
    desc = 'Move left',
  })

  map('n', '<C-j>', function()
    navigate_window_or_tmux('j')
  end, {
    desc = 'Move down',
  })

  map('n', '<C-k>', function()
    navigate_window_or_tmux('k')
  end, {
    desc = 'Move up',
  })

  map('n', '<C-l>', function()
    navigate_window_or_tmux('l')
  end, {
    desc = 'Move right',
  })
