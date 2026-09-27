local function set_highlights()
  local links = {
    Header = 'Statement',
    Desc = 'Normal',
    Key = 'Number',
    Title = 'Title',
    File = 'Normal',
    Dir = 'Comment',
    Footer = 'Comment',
    Startup = 'Special',
  }

  for name, target in pairs(links) do
    vim.api.nvim_set_hl(0, 'SnacksDashboard' .. name, { link = target })
  end

  if vim.g.colors_name == 'mellow' then
    local colors = require('mellow.colors')[vim.o.background]
    vim.api.nvim_set_hl(0, 'SnacksDashboardHeader', { fg = colors.blue, bold = true })
    vim.api.nvim_set_hl(0, 'SnacksDashboardKey', { fg = colors.yellow, bold = true })
    vim.api.nvim_set_hl(0, 'SnacksDashboardTitle', { fg = colors.green, bold = true })
    vim.api.nvim_set_hl(0, 'SnacksDashboardStartup', { fg = colors.green, bold = true })
  end
end

set_highlights()
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('user_dashboard_colors', { clear = true }),
  callback = set_highlights,
})

return {
  enabled = true,
  width = 56,
  formats = {
    key = { '[%s]', align = 'right' },
  },
  preset = {
    header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
    keys = {
      { key = 'f', desc = 'Find file', action = ":lua Snacks.dashboard.pick('files')" },
      { key = 'n', desc = 'New file', action = ':ene | startinsert' },
      { key = 'g', desc = 'Find text', action = ":lua Snacks.dashboard.pick('live_grep')" },
      { key = 'r', desc = 'Recent files', action = ":lua Snacks.dashboard.pick('oldfiles')" },
      { key = 'c', desc = 'Edit config', action = ":lua Snacks.dashboard.pick('files', { cwd = vim.fn.stdpath('config') })" },
      { key = 'q', desc = 'Quit', action = ':qa' },
    },
  },
  -- Explicit sections avoid the default startup stats, which require lazy.nvim.
  sections = {
    function(self)
      if self:size().height >= 24 and self:size().width >= 60 and vim.fn.executable('python3') == 1 then
        local height = self:size().height >= 32 and 12 or self:size().height >= 28 and 10 or 8
        return {
          {
            section = 'terminal',
            cmd = {
              'python3',
              vim.fn.stdpath('config') .. '/scripts/dashboard-donut.py',
              tostring(self.opts.width),
              tostring(height),
            },
            height = height,
            ttl = 0,
          },
          { header = 'N E O V I M', padding = 1 },
        }
      end
      local compact = self:size().height < 22 or self:size().width < 60
      return { header = compact and 'N E O V I M' or self.opts.preset.header, padding = 1 }
    end,
    { section = 'keys' },
    function(self)
      local startup = string.format('%.2f ms', (vim.uv.hrtime() - vim.g.nvim_startup_time) / 1e6)
      local text = {}

      if self:size().height >= 32 then
        local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ':~')
        if vim.fn.strdisplaywidth(cwd) > self.opts.width then
          cwd = vim.fn.pathshorten(cwd)
        end
        table.insert(text, { cwd, hl = 'SnacksDashboardFooter' })
        table.insert(text, { '\n\n' })
      end

      table.insert(text, { 'Nvim loaded in ', hl = 'SnacksDashboardFooter' })
      table.insert(text, { startup, hl = 'SnacksDashboardStartup' })
      return { text = text, align = 'center', padding = { 0, 2 } }
    end,
  },
}
