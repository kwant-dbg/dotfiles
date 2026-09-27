vim.pack.add({
	{
		src = "https://github.com/lewis6991/gitsigns.nvim",
	},
})

require("gitsigns").setup({
	current_line_blame = false,
	current_line_blame_opts = {
		delay = 500,
		virt_text_pos = "eol",
	},

	on_attach = function(bufnr)
		local gitsigns = require("gitsigns")

		local function map(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, {
				buffer = bufnr,
				desc = desc,
			})
		end

		map("n", "]h", function()
			gitsigns.nav_hunk("next")
		end, "Next hunk")

		map("n", "[h", function()
			gitsigns.nav_hunk("prev")
		end, "Previous hunk")

		map("n", "<leader>ghs", gitsigns.stage_hunk, "Stage hunk")
		map("n", "<leader>ghr", gitsigns.reset_hunk, "Reset hunk")
		map("n", "<leader>ghp", gitsigns.preview_hunk, "Preview hunk")
		map("n", "<leader>ghb", function()
			gitsigns.blame_line({ full = true })
		end, "Blame line")
		map("n", "<leader>ghB", gitsigns.blame, "Blame file")
		map("n", "<leader>ght", gitsigns.toggle_current_line_blame, "Toggle inline blame")
		map("n", "<leader>ghS", gitsigns.stage_buffer, "Stage buffer")
		map("n", "<leader>ghR", gitsigns.reset_buffer, "Reset buffer")

		map("v", "<leader>ghs", function()
			gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, "Stage selected hunk")

		map("v", "<leader>ghr", function()
			gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, "Reset selected hunk")
	end,
})
