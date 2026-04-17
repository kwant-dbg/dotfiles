return {
  "nvim-telescope/telescope.nvim",
  keys = {
    -- Scoped grep - prompt for directory
    {
      "<leader>f/",
      function()
        require("telescope.builtin").live_grep({
          search_dirs = { vim.fn.input("Dir: ", vim.fn.getcwd() .. "/", "dir") },
        })
      end,
      desc = "Grep in directory",
    },
  },
}
