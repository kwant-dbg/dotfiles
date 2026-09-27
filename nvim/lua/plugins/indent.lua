vim.pack.add({
	{
		src = "https://github.com/folke/snacks.nvim",
	},
})

require("snacks").setup({
	picker = {
		enabled = true,
	},
	scroll = {
		enabled = true,
	},
	dashboard = require("plugins.dashboard"),
	indent = {
		indent = {
			enabled = true,
			char = "│",
		},
		scope = {
			enabled = true,
			char = "│",
		},
		chunk = {
			enabled = false,
		},
		animate = {
			enabled = true,
			style = "out",
			easing = "linear",
			duration = {
				step = 20,
				total = 300,
			},
		},
	},
})

local function set_indent_highlights()
	vim.api.nvim_set_hl(0, "SnacksIndent", { fg = "#4a4a4a" })
end

set_indent_highlights()

vim.api.nvim_create_autocmd("ColorScheme", {
	callback = set_indent_highlights,
})
