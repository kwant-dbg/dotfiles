return {
  { "rebelot/kanagawa.nvim", enabled = false },
  { "rose-pine/neovim", name = "rose-pine", enabled = false },
  {
    "mellow-theme/mellow.nvim",
    init = function()
      local palette = require("config.palette")

      vim.g.mellow_highlight_overrides = {
        Normal = { bg = palette.bg },
        NormalFloat = { bg = palette.bg },
        NormalNC = { bg = palette.bg },

        -- more vibrant syntax
        String = { fg = palette.green_string },
        Character = { fg = palette.green_string },
        ["@string"] = { fg = palette.green_string },

        Keyword = { fg = palette.purple_keyword },
        Conditional = { fg = palette.purple_keyword },
        Repeat = { fg = palette.purple_keyword },
        Label = { fg = palette.purple_keyword },
        Exception = { fg = palette.purple_keyword },
        Include = { fg = palette.purple_keyword },
        ["@keyword"] = { fg = palette.purple_keyword },
        ["@keyword.function"] = { fg = palette.red },

        Function = { fg = palette.purple },
        ["@function"] = { fg = palette.purple },
        ["@function.builtin"] = { fg = palette.red },
        ["@function.method"] = { fg = palette.purple },

        Type = { fg = palette.purple_type },
        ["@type"] = { fg = palette.purple_type },
        ["@type.builtin"] = { fg = palette.pink },

        Number = { fg = palette.pink },
        Float = { fg = palette.pink },
        Boolean = { fg = palette.orange },
        Operator = { fg = palette.orange },

        ["@parameter"] = { fg = palette.pink },
        ["@variable.parameter"] = { fg = palette.pink },
      }
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "mellow",
    },
  },
}
