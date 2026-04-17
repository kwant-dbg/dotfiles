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
    require("render-markdown").setup(opts)
    -- Kanagawa Dragon: heading colors per level
    vim.api.nvim_set_hl(0, "RenderMarkdownH1", { fg = "#c4746e", bold = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownH2", { fg = "#c4b28a", bold = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownH3", { fg = "#8a9a7b", bold = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownH4", { fg = "#8ea4a2", bold = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownH5", { fg = "#8ba4b0", bold = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownH6", { fg = "#a292a3", bold = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownH1Bg", { bg = "#261e1e" })
    vim.api.nvim_set_hl(0, "RenderMarkdownH2Bg", { bg = "#252018" })
    vim.api.nvim_set_hl(0, "@markup.strong", { fg = "#e7d3b0", bold = true })
    vim.api.nvim_set_hl(0, "@markup.italic", { fg = "#b3b8c4", italic = true })
    vim.api.nvim_set_hl(0, "@markup.raw.inline", { fg = "#c4746e" })
    vim.api.nvim_set_hl(0, "@markup.link", { fg = "#8ba4b0", underline = true, sp = "#8ba4b0" })
    vim.api.nvim_set_hl(0, "@markup.link.url", { fg = "#8ea4a2", underline = true, sp = "#8ea4a2" })
  end,
}
