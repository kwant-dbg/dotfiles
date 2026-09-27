local M = {}

local INDENT_WIDTH = 4
local HEADING_GLYPHS = { "◉", "◆", "▸", "•", "‣", "◦", "▪", "·" }
local DECORATION_NAMESPACE = vim.api.nvim_create_namespace("org_formatting")

local HIGHLIGHT_LINKS = {
	["@org.headline.level1"] = "Title",
	["@org.headline.level2"] = "Function",
	["@org.headline.level3"] = "String",
	["@org.headline.level4"] = "Type",
	["@org.headline.level5"] = "Identifier",
	["@org.headline.level6"] = "Constant",
	["@org.headline.level7"] = "Special",
	["@org.headline.level8"] = "PreProc",
	["@org.bold"] = "Special",
	["@org.italic"] = "Comment",
	["@org.underline"] = "Underlined",
	["@org.code"] = "String",
	["@org.verbatim"] = "String",
	["@org.strikethrough"] = "Comment",
	OrgCheckboxTodo = "DiagnosticWarn",
	OrgCheckboxProgress = "DiagnosticInfo",
	OrgCheckboxDone = "DiagnosticOk",
}

local CHECKBOX_STYLES = {
	[" "] = { glyph = "☐", highlight = "OrgCheckboxTodo" },
	["-"] = { glyph = "◐", highlight = "OrgCheckboxProgress" },
	["x"] = { glyph = "✓", highlight = "OrgCheckboxDone" },
	["X"] = { glyph = "✓", highlight = "OrgCheckboxDone" },
}

---@class OrgLine
---@field kind "heading"|"unordered_list"|"ordered_list"
---@field level? integer
---@field indent? string
---@field marker? string
---@field number? integer
---@field separator? string
---@field checkbox? boolean
---@field empty? boolean

---@param line string
---@return OrgLine?
local function parse_line(line)
	local stars = line:match("^(%*+)%s+")
	if stars then
		return { kind = "heading", level = #stars }
	end

	local indent, marker, checkbox, content = line:match("^(%s*)([-+])%s+%[([ xX%-])%]%s*(.*)$")
	if marker then
		return {
			kind = "unordered_list",
			indent = indent,
			marker = marker,
			checkbox = checkbox ~= nil,
			empty = content == "",
		}
	end

	indent, marker, content = line:match("^(%s*)([-+])%s+(.*)$")
	if marker then
		return {
			kind = "unordered_list",
			indent = indent,
			marker = marker,
			empty = content == "",
		}
	end

	local number, separator
	indent, number, separator, content = line:match("^(%s*)(%d+)([.)])%s+(.*)$")
	if number then
		return {
			kind = "ordered_list",
			indent = indent,
			number = tonumber(number),
			separator = separator,
			empty = content == "",
		}
	end
end

local function apply_highlights()
	for group, target in pairs(HIGHLIGHT_LINKS) do
		vim.api.nvim_set_hl(0, group, { link = target })
	end
end

---@param bufnr integer
---@param row integer
---@param level integer
local function decorate_heading(bufnr, row, level)
	local indent = (level - 1) * INDENT_WIDTH
	local options = {
		end_col = level,
		conceal = HEADING_GLYPHS[level] or HEADING_GLYPHS[#HEADING_GLYPHS],
		right_gravity = false,
		priority = 200,
	}

	if indent > 0 then
		options.virt_text = { { string.rep(" ", indent), "OrgIndent" } }
		options.virt_text_pos = "inline"
	end

	vim.api.nvim_buf_set_extmark(bufnr, DECORATION_NAMESPACE, row, 0, options)
end

---@param bufnr integer
---@param row integer
---@param line string
local function decorate_checkboxes(bufnr, row, line)
	local search_from = 1

	while true do
		local start_col, end_col, state = line:find("%[([ xX%-])%]", search_from)
		if not start_col then
			return
		end

		local style = CHECKBOX_STYLES[state]
		vim.api.nvim_buf_set_extmark(bufnr, DECORATION_NAMESPACE, row, start_col - 1, {
			end_col = end_col,
			conceal = style.glyph,
			hl_group = style.highlight,
			priority = 200,
		})

		search_from = end_col + 1
	end
end

---@param bufnr integer
local function render(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	vim.api.nvim_buf_clear_namespace(bufnr, DECORATION_NAMESPACE, 0, -1)

	for index, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
		local row = index - 1
		local structure = parse_line(line)

		if structure and structure.kind == "heading" then
			decorate_heading(bufnr, row, structure.level)
		end

		decorate_checkboxes(bufnr, row, line)
	end
end

---@return string
local function continue_line()
	local line = vim.api.nvim_get_current_line()

	-- Inserting in the middle of a line should behave like an ordinary Enter.
	if vim.fn.col(".") <= #line then
		return "<CR>"
	end

	local structure = parse_line(line)
	if not structure then
		return "<CR>"
	end

	if structure.kind ~= "heading" and structure.empty then
		return "<C-u>" .. (structure.indent or "")
	end

	if structure.kind == "heading" then
		return "<CR><C-u>" .. string.rep(" ", structure.level * INDENT_WIDTH)
	end

	if structure.kind == "unordered_list" then
		local checkbox = structure.checkbox and " [ ]" or ""
		return ("<CR><C-u>%s%s%s "):format(structure.indent, structure.marker, checkbox)
	end

	return ("<CR><C-u>%s%d%s "):format(structure.indent, structure.number + 1, structure.separator)
end

---@return string
local function insert_star()
	local line = vim.api.nvim_get_current_line()
	local before_cursor = line:sub(1, vim.fn.col(".") - 1)

	-- Org headings must begin in column zero. This lets a heading be started
	-- directly from an indented body line without storing invalid indentation.
	if before_cursor:match("^%s+$") then
		return "<C-u>*"
	end

	return "*"
end

---@param bufnr integer
local function configure_buffer(bufnr)
	vim.opt_local.conceallevel = 2
	vim.opt_local.concealcursor = "nvic"
	vim.opt_local.wrap = true
	vim.opt_local.linebreak = true

	vim.keymap.set("i", "*", insert_star, {
		buffer = bufnr,
		expr = true,
		desc = "Insert Org heading star",
	})
	vim.keymap.set("i", "<CR>", continue_line, {
		buffer = bufnr,
		expr = true,
		desc = "Continue Org structure",
	})

	render(bufnr)
end

function M.setup()
	local group = vim.api.nvim_create_augroup("org_formatting", { clear = true })

	apply_highlights()

	vim.api.nvim_create_autocmd("ColorScheme", {
		group = group,
		callback = apply_highlights,
	})
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = "org",
		callback = function(event)
			configure_buffer(event.buf)
		end,
	})
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = group,
		callback = function(event)
			if vim.bo[event.buf].filetype == "org" then
				render(event.buf)
			end
		end,
	})
end

return M
