  vim.pack.add({
    {
      src = 'https://github.com/folke/sidekick.nvim',
    },
  })

  require('sidekick').setup({
    -- Disable Copilot Next Edit Suggestions because your current config
    -- does not have Copilot LSP configured.
    nes = {
      enabled = false,
    },

    cli = {
      mux = {
        backend = 'tmux',
        enabled = true,
      },
    },
  })

  local map = vim.keymap.set

  map('n', '<leader>aa', function()
    require('sidekick.cli').toggle()
  end, {
    desc = 'Toggle AI CLI',
  })

  map('n', '<leader>ac', function()
    require('sidekick.cli').toggle({
      name = 'claude',
      focus = true,
    })
  end, {
    desc = 'Toggle Claude Code',
  })

  map('n', '<leader>ax', function()
    require('sidekick.cli').toggle({
      name = 'codex',
      focus = true,
    })
  end, {
    desc = 'Toggle Codex',
  })

  map('n', '<leader>as', function()
    require('sidekick.cli').select()
  end, {
    desc = 'Select AI CLI',
  })

  map({ 'n', 'x' }, '<leader>at', function()
    require('sidekick.cli').send({
      msg = '{this}',
    })
  end, {
    desc = 'Send context to AI',
  })

  map('x', '<leader>av', function()
    require('sidekick.cli').send({
      msg = '{selection}',
    })
  end, {
    desc = 'Send selection to AI',
  })
