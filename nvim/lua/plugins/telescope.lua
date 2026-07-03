return {
  "nvim-telescope/telescope.nvim",
  keys = {
    -- Scoped grep - prompt for directory
    {
      "<leader>f/",
      function()
        require("telescope.builtin").live_grep({
          search_dirs = { vim.fn.input("Dir: ", vim.fn.getcwd() .. "/", "dir") },
          additional_args = { "--no-ignore" },
        })
      end,
      desc = "Grep in directory",
    },
    {
      "<leader>sg",
      function()
        require("telescope.builtin").live_grep({
          search_dirs = { vim.fn.getcwd() },
          additional_args = { "--no-ignore" },
        })
      end,
      desc = "Grep cwd",
    },
    {
      "<leader>sG",
      function()
        local file = vim.api.nvim_buf_get_name(0)
        local dir = file ~= "" and vim.fs.dirname(file) or vim.fn.getcwd()

        require("telescope.builtin").live_grep({
          search_dirs = { dir },
          additional_args = { "--no-ignore" },
        })
      end,
      desc = "Grep current file directory",
    },
    {
      "<leader>ro",
      function()
        require("telescope.builtin").live_grep({
          search_dirs = { vim.fn.expand("~/notes/roam") },
          glob_pattern = "*.org",
          additional_args = { "--no-ignore" },
        })
      end,
      desc = "Grep roam notes",
    },
  },
}
