vim.pack.add({
  {
    src = 'https://github.com/Saghen/blink.cmp',
    version = vim.version.range('^1'),
  },
  {
    src = 'https://github.com/rafamadriz/friendly-snippets',
  },
  {
    src = 'https://github.com/kwant-dbg/templates',
  },
})

local template_snippets = vim.api.nvim_get_runtime_file('cpp.json', false)[1]
local template_snippets_dir = template_snippets and vim.fs.dirname(template_snippets)

require('blink.cmp').setup({
  keymap = {
    preset = 'default',
    ['<Tab>'] = { 'select_and_accept', 'fallback' },
  },
  completion = {
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 300,
    },
  },
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
    providers = {
      snippets = {
        opts = {
          search_paths = template_snippets_dir and { template_snippets_dir } or {},
        },
      },
    },
  },
  signature = { enabled = true },
  fuzzy = { implementation = 'prefer_rust' },
})
