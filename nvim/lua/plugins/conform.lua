return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      -- C/C++ formatting
      c = { "clang_format" },
      cpp = { "clang_format" },

      -- Go formatting with import management
      go = { "goimports", "gofmt" },

    },
  },
}
