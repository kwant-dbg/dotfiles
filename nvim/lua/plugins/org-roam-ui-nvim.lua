local local_path = vim.fn.expand("~/dev/org-roam-ui.nvim")

return {
  {
    dir = local_path,
    name = "org-roam-ui-nvim",
    enabled = vim.fn.isdirectory(local_path) == 1,
    dependencies = { "chipsenkbeil/org-roam.nvim" },
    keys = {
      { "<leader>rg", "<cmd>OrgRoamUiStart<cr>", desc = "Org Roam UI" },
    },
    config = function()
      require("org-roam-ui-nvim").setup({
        port = 35911,
        websocket_port = 35913,
        open_on_start = true,
        follow_on_switch = true,
      })
    end,
  },
}
