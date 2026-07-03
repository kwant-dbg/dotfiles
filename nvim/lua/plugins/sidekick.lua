return {
  -- main plugin
  {
    "folke/sidekick.nvim",
    cmd = "Sidekick",
    keys = {
      {
        "<tab>",
        function()
          if not require("sidekick").nes_jump_or_apply() then
            return "<Tab>"
          end
        end,
        expr = true,
        desc = "Goto/Apply Next Edit Suggestion",
      },
      { "<c-.>",     function() require("sidekick.cli").focus() end,                              mode = { "n", "t", "i", "x" }, desc = "Sidekick Focus" },
      { "<leader>aa", function() require("sidekick.cli").toggle() end,                            desc = "Toggle AI CLI" },
      { "<leader>ac", function() require("sidekick.cli").toggle({ name = "claude", focus = true }) end, desc = "Toggle Claude" },
      { "<leader>as", function() require("sidekick.cli").select() end,                            desc = "Select CLI tool" },
      { "<leader>ad", function() require("sidekick.cli").close() end,                             desc = "Detach CLI session" },
      { "<leader>at", function() require("sidekick.cli").send({ msg = "{this}" }) end,            mode = { "n", "x" }, desc = "Send context" },
      { "<leader>af", function() require("sidekick.cli").send({ msg = "{file}" }) end,            desc = "Send file" },
      { "<leader>av", function() require("sidekick.cli").send({ msg = "{selection}" }) end,       mode = "x", desc = "Send selection" },
      { "<leader>ap", function() require("sidekick.cli").prompt() end,                            mode = { "n", "x" }, desc = "AI prompt picker" },
    },
    opts = {
      cli = {
        mux = {
          backend = "tmux",
          enabled = true,
        },
        win = {
          -- route nav through tmux-navigator so C-h/j/k/l cross tmux panes
          nav = function(dir)
            local cmds = { h = "TmuxNavigateLeft", j = "TmuxNavigateDown", k = "TmuxNavigateUp", l = "TmuxNavigateRight" }
            vim.cmd(cmds[dir])
          end,
        },
      },
    },
  },

  -- blink.cmp: hook Tab in insert mode for NES
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      keymap = {
        ["<Tab>"] = {
          "snippet_forward",
          function() return require("sidekick").nes_jump_or_apply() end,
          "fallback",
        },
      },
    },
  },

  -- snacks: send picker selections to AI with <a-a>
  {
    "folke/snacks.nvim",
    optional = true,
    opts = {
      picker = {
        actions = {
          sidekick_send = function(...)
            return require("sidekick.cli.picker.snacks").send(...)
          end,
        },
        win = {
          input = {
            keys = {
              ["<a-a>"] = { "sidekick_send", mode = { "n", "i" } },
            },
          },
        },
      },
    },
  },
}

