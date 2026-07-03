-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local palette = require("config.palette")

local function apply_comment_hl()
  vim.api.nvim_set_hl(0, "Comment", { fg = palette.comment, italic = true })
  vim.api.nvim_set_hl(0, "@comment", { fg = palette.comment, italic = true })
end

apply_comment_hl()

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = apply_comment_hl,
})

local function apply_visual_hl()
  vim.api.nvim_set_hl(0, "Visual", { bg = palette.visual })
  vim.api.nvim_set_hl(0, "VisualNOS", { bg = palette.visual })
end

apply_visual_hl()

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = apply_visual_hl,
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = apply_visual_hl,
})

-- Better-Comments-style colorful tags
-- Overrides treesitter @comment via high-priority extmarks
local bc_tags = {
  { keyword = "^", fg = palette.better_comment_yellow },
  { keyword = "*", fg = palette.better_comment_green },
  { keyword = "&", fg = palette.better_comment_pink },
  { keyword = "~", fg = palette.better_comment_purple },
}

local bc_ns = vim.api.nvim_create_namespace("better_comments_tags")

local function bc_set_hl()
  for i, t in ipairs(bc_tags) do
    vim.api.nvim_set_hl(0, "BCTag" .. i, { fg = t.fg, italic = true })
  end
end
bc_set_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = bc_set_hl })

local function bc_escape(c) return (c:gsub("(%W)", "%%%1")) end

local function bc_refresh(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_buf_get_name(buf) == "" then return end

  local ft = vim.bo[buf].filetype
  if ft == "" then return end

  local ok, parser = pcall(vim.treesitter.get_parser, buf, ft)
  if not ok or not parser then return end

  local tree = parser:parse()[1]
  if not tree then return end

  local qok, query = pcall(vim.treesitter.query.parse, ft, "(comment) @c")
  if not qok then return end

  vim.api.nvim_buf_clear_namespace(buf, bc_ns, 0, -1)

  for _, node in query:iter_captures(tree:root(), buf, 0, -1) do
    local sr, _, er = node:range()
    for lnum = sr, er do
      local line = vim.api.nvim_buf_get_lines(buf, lnum, lnum + 1, false)[1] or ""
      local stripped = line:match("^%s*//+%s*(.*)$")
        or line:match("^%s*/%*+%s*(.*)$")
        or line:match("^%s*%*+%s*(.*)$")
        or line:match("^%s*(.*)$") -- bare line inside /* */ block
      if stripped then
        for i, t in ipairs(bc_tags) do
          if stripped:match("^" .. bc_escape(t.keyword)) then
            local col = (line:find("%S") or 1) - 1
            pcall(vim.api.nvim_buf_set_extmark, buf, bc_ns, lnum, col, {
              end_col = #line,
              hl_group = "BCTag" .. i,
              priority = 200,
            })
            break
          end
        end
      end
    end
  end
end

vim.api.nvim_create_autocmd(
  { "BufReadPost", "BufWinEnter", "BufWritePost", "TextChanged", "InsertLeave" },
  {
    callback = function(args)
      bc_refresh(args.buf)
    end,
  }
)
