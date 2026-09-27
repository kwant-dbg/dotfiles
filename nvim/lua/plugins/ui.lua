vim.pack.add({
  {
    src = 'https://github.com/nvim-mini/mini.statusline',
    version = 'stable',
  },
})

local statusline = require('mini.statusline')

local function project_filename()
  local file = vim.api.nvim_buf_get_name(0)
  if file == '' or vim.bo.buftype ~= '' then
    return statusline.section_filename({ trunc_width = 140 })
  end

  local root = vim.fs.root(file, '.git')
    or vim.fs.root(file, { 'pyproject.toml', 'package.json', 'Cargo.toml', 'go.mod', 'pom.xml' })
    or vim.uv.cwd()
  local path = vim.fs.relpath(root, file) or vim.fn.fnamemodify(file, ':~')
  -- Percent signs in file names must be escaped in a statusline expression.
  return path:gsub('%%', '%%%%') .. '%m%r'
end

local function active()
  local mode, mode_hl = statusline.section_mode({ trunc_width = 80 })
  local filename = project_filename()
  local git = statusline.section_git({ trunc_width = 60 })
  local diagnostics = statusline.section_diagnostics({ trunc_width = 70 })

  local icon = ''
  if vim.bo.filetype ~= '' then
    icon = require('mini.icons').get('filetype', vim.bo.filetype) or ''
  end

  return statusline.combine_groups({
    { hl = mode_hl, strings = { mode } },
    { hl = 'MiniStatuslineFilename', strings = { icon, filename } },
    '%=',
    { hl = 'UserStatuslineGit', strings = { git } },
    { hl = 'MiniStatuslineDevinfo', strings = { diagnostics } },
  })
end

statusline.setup({
  use_icons = true,
  content = { active = active },
})

local function set_git_highlight()
  local devinfo = vim.api.nvim_get_hl(0, { name = 'MiniStatuslineDevinfo', link = false })
  vim.api.nvim_set_hl(0, 'UserStatuslineGit', {
    fg = vim.o.background == 'dark' and '#d49a86' or '#a95645',
    bg = devinfo.bg,
    bold = true,
  })
end

set_git_highlight()
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('user_statusline_colors', { clear = true }),
  callback = set_git_highlight,
})
