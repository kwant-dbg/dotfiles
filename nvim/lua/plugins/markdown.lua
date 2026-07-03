return {
  "MeanderingProgrammer/render-markdown.nvim",
  version = "8.12.0",
  ft = { "markdown" },
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  opts = {
    heading = {
      icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
    },
    bullet = {
      icons = { "●", "○", "◆", "◇" },
    },
    code = {
      sign = false,
      width = "block",
      right_pad = 1,
    },
    quote = {
      icon = "▋",
    },
  },
  config = function(_, opts)
    local palette = require("config.palette")

    require("render-markdown").setup(opts)
    -- Kanagawa Dragon: heading colors per level
    vim.api.nvim_set_hl(0, "RenderMarkdownH1", { fg = palette.red_soft, bold = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownH2", { fg = palette.yellow_muted, bold = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownH3", { fg = palette.green_muted, bold = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownH4", { fg = palette.cyan_soft, bold = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownH5", { fg = palette.cyan_muted, bold = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownH6", { fg = palette.purple_soft, bold = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownH1Bg", { bg = palette.bg_markdown_h1 })
    vim.api.nvim_set_hl(0, "RenderMarkdownH2Bg", { bg = palette.bg_markdown_h2 })
    vim.api.nvim_set_hl(0, "@markup.strong", { fg = palette.fg_markdown_bold, bold = true })
    vim.api.nvim_set_hl(0, "@markup.italic", { fg = palette.fg_markdown_italic, italic = true })
    vim.api.nvim_set_hl(0, "@markup.raw.inline", { fg = palette.red_soft })
    vim.api.nvim_set_hl(0, "@markup.link", { fg = palette.cyan_muted, underline = true, sp = palette.cyan_muted })
    vim.api.nvim_set_hl(0, "@markup.link.url", { fg = palette.cyan_soft, underline = true, sp = palette.cyan_soft })
  end,
}
