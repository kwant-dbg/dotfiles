vim.pack.add({
	{
		src = "https://github.com/folke/which-key.nvim",
		version = vim.version.range("3.*"),
	},
})

require("which-key").setup({
	preset = "helix",
	delay = 300,

	icons = {
		mappings = false,
	},

	spec = {
		{ "<leader>b", group = "Buffers" },
		{ "<leader>c", group = "Code" },
		{ "<leader>f", group = "Find" },
		{ "<leader>q", group = "Quickfix" },
		{ "<leader>g", group = "Git" },
		{ "<leader>t", group = "Tests" },
	},
})
