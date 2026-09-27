local ROAM_DIRECTORY = vim.env.ORG_ROAM_DIR or vim.fn.expand("~/notes/roam")
local PERMANENT_DIRECTORY = vim.fs.joinpath(ROAM_DIRECTORY, "permanent")
local M = {}
local roam
local loaded = false

local function install_plugins()
	vim.pack.add({
		{
			src = "https://github.com/nvim-orgmode/orgmode",
			version = vim.version.range("0.7.*"),
		},
		{
			src = "https://github.com/chipsenkbeil/org-roam.nvim",
			version = vim.version.range("0.2.*"),
		},
		{
			src = "https://github.com/kwant-dbg/org-roam-ui.nvim",
		},
	})
end

local function setup_orgmode()
	require("orgmode").setup({
		org_agenda_files = { vim.fs.joinpath(ROAM_DIRECTORY, "**", "*.org") },
		org_default_notes_file = vim.fs.joinpath(PERMANENT_DIRECTORY, "inbox.org"),
		win_split_mode = "float",
		org_hide_emphasis_markers = true,
		org_hide_leading_stars = false,
		org_startup_indented = false,
		org_startup_folded = "showeverything",
		org_ellipsis = " ▾",
	})

	require("config.org-formatting").setup()
end

local function setup_roam()
	local roam = require("org-roam")

	roam.setup({
		directory = ROAM_DIRECTORY,
		bindings = false,
		immediate = {
			target = "permanent/%[slug].org",
			template = "#+filetags: :permanent:\n#+date: %<%Y-%m-%d>\n\n* Related notes\n    ",
		},
		templates = {
			p = {
				description = "Permanent note",
				target = "permanent/%[slug].org",
				header = "#+title: ${title}\n#+filetags: :permanent:\n#+date: %<%Y-%m-%d>\n",
				template = "%?\n\n* Related notes\n",
			},
		},
	})

	return roam
end

local function open_node(roam, id, window, start_editing)
	local node = roam.database:get_sync(id)
	if not node then
		return
	end

	pcall(vim.api.nvim_set_current_win, window)
	vim.cmd.edit({ node.file, bang = true })
	vim.cmd.filetype("detect")

	if start_editing then
		vim.cmd.normal({ "G$", bang = true })
		vim.cmd.startinsert({ bang = true })
		return
	end

	vim.cmd.stopinsert()
	vim.schedule(function()
		if vim.api.nvim_win_is_valid(window) then
			vim.api.nvim_win_set_cursor(window, {
				node.range.start.row + 1,
				node.range.start.column,
			})
		end
	end)
end

local function create_permanent_note(roam, title, window)
	roam.api.capture_node({ immediate = true, title = title }):next(function(id)
		if not id then
			return
		end

		open_node(roam, id, window, true)
		return id
	end)
end

local function find_or_create_permanent_note(roam)
	local window = vim.api.nvim_get_current_win()

	roam.ui
		.select_node({ allow_select_missing = true })
		:on_choice(function(choice)
			open_node(roam, choice.id, window, false)
		end)
		:on_choice_missing(function(title)
			create_permanent_note(roam, title, window)
		end)
		:open()
end

local function setup_graph()
	-- The server listens only on this machine and starts only on demand.
	require("org-roam-ui-nvim").setup({
		host = "127.0.0.1",
		port = 35911,
		websocket_port = 35913,
		open_on_start = true,
		refresh_on_save = true,
		follow_on_switch = false,
		auto_sync_theme = false,
		create_immediate = false,
	})
end

local function setup_keymaps()
	require("which-key").add({ { "<leader>r", group = "Org roam" } })

	local function map(lhs, action, description)
		vim.keymap.set("n", lhs, function()
			M.setup()
			action()
		end, { desc = description })
	end

	map("<leader>ra", function()
		require("orgmode").action("agenda.prompt")
	end, "Org agenda")
	map("<leader>rf", function()
		find_or_create_permanent_note(roam)
	end, "Find or create Org-roam node")
	map("<leader>ri", function()
		roam.api.insert_node()
	end, "Insert Org-roam link")
	map("<leader>rb", function()
		roam.ui.toggle_node_buffer()
	end, "Toggle Org-roam backlinks")
	map("<leader>rg", function()
		vim.cmd("OrgRoamUiStart")
	end, "Start Org-roam graph")
	map("<leader>rG", function()
		vim.cmd("OrgRoamUiStop")
	end, "Stop Org-roam graph")
end

install_plugins()
setup_keymaps()

function M.setup()
	if loaded then
		return
	end

	loaded = true
	setup_orgmode()
	roam = setup_roam()
	setup_graph()
end

vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
	group = vim.api.nvim_create_augroup("user_org_roam_lazy", { clear = true }),
	pattern = "*.org",
	callback = function()
		M.setup()
	end,
})

return M
