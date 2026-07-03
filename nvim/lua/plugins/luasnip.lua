return {
  "L3MON4D3/LuaSnip",
  event = "InsertEnter",
  config = function(_, opts)
    vim.fn.mkdir(vim.fn.stdpath("log"), "p")

    require("luasnip").setup(opts)
    require("luasnip.loaders.from_vscode").lazy_load({
      paths = { vim.fn.stdpath("config") .. "/snippets" },
    })
  end,
}
