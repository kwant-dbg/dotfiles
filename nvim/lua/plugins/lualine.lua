return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- Left: mode | git-dir  branch | filename
      opts.sections.lualine_a = {
        {
          function()
            local mode = vim.fn.mode()
            if mode == "n" and vim.bo.buftype == "terminal" then
              return "T-NORMAL"
            end
            local names = {
              n = "NORMAL",   i = "INSERT",   v = "VISUAL",
              V = "V-LINE",   ["\22"] = "V-BLOCK",
              c = "COMMAND",  t = "T-INSERT", R = "REPLACE",
              s = "SELECT",   S = "S-LINE",
            }
            return names[mode] or mode:upper()
          end,
        },
      }
      opts.sections.lualine_b = {
        {
          function()
            local dir = vim.fn.expand("%:p:h")
            local root = vim.fn.systemlist("git -C " .. vim.fn.shellescape(dir) .. " rev-parse --show-toplevel 2>/dev/null")[1]
            if root and root ~= "" and not root:find("^fatal") then
              return vim.fn.fnamemodify(root, ":t")
            end
            return ""
          end,
          icon = "",
          color = { fg = "#90b99f" },
        },
        { "branch", color = { fg = "#90b99f" } },
      }
      opts.sections.lualine_c = {
        { "filename", path = 0, symbols = { modified = " ●", readonly = " ", unnamed = "[No Name]" } },
      }

      -- Right: diagnostics | filetype
      opts.sections.lualine_x = {
        {
          "diagnostics",
          sources = { "nvim_lsp", "nvim_diagnostic" },
          symbols = { error = " ", warn = " ", info = " ", hint = " " },
        },
      }
      opts.sections.lualine_y = { "filetype" }
      opts.sections.lualine_z = {}

      return opts
    end,
  },
}
