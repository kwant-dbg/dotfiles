return {
  { "nvim-neo-tree/neo-tree.nvim", enabled = false },
  {
    "nvim-mini/mini.files",
    lazy = false,
    version = "*",
    opts = {
      windows = {
        preview = true,
        width_preview = 50,
      },
    },
    config = function(_, opts)
      require("mini.files").setup(opts)
      local palette = require("config.palette")

      local function apply_highlights()
        vim.api.nvim_set_hl(0, "MiniFilesNormal", { fg = palette.fg_dashboard_desc, bg = palette.bg })
        vim.api.nvim_set_hl(0, "MiniFilesBorder", { fg = palette.muted_deep, bg = palette.bg })
        vim.api.nvim_set_hl(0, "MiniFilesCursorLine", { bg = palette.bg_tab })
        vim.api.nvim_set_hl(0, "MiniFilesDirectory", { fg = palette.blue_soft })
        vim.api.nvim_set_hl(0, "MiniFilesFile", { fg = palette.fg_dashboard_desc })
        vim.api.nvim_set_hl(0, "MiniFilesTitle", { fg = palette.yellow_muted, bold = true })
        vim.api.nvim_set_hl(0, "MiniFilesTitleFocused", { fg = palette.yellow_muted, bold = true })
      end

      apply_highlights()
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = apply_highlights,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniFilesBufferCreate",
        callback = function(args)
          vim.keymap.set("n", "gy", function()
            local entry = require("mini.files").get_fs_entry()
            if entry then
              vim.fn.setreg("+", entry.path)
              vim.notify("Copied: " .. entry.path)
            end
          end, { buffer = args.data.buf_id, desc = "Yank path" })
        end,
      })
    end,
    keys = {
      { "<leader>e", function() require("mini.files").open(vim.api.nvim_buf_get_name(0)) end, desc = "Explorer (current file)" },
      { "<leader>E", function() require("mini.files").open() end, desc = "Explorer (cwd)" },
    },
  },
}
