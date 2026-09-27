vim.pack.add({
  {
    src = 'https://github.com/nvim-treesitter/nvim-treesitter',
    version = 'main',
  },
})

-- Terraform variable files share the Terraform grammar.
vim.treesitter.language.register('terraform', 'terraform-vars')
vim.opt.foldlevelstart = 99

local filetypes = {
  'bash', 'c', 'cpp', 'go', 'gomod', 'gowork', 'gotmpl', 'hcl',
  'json', 'lua', 'markdown', 'python', 'terraform', 'terraform-vars',
  'yaml', 'yaml.docker-compose', 'yaml.gitlab',
}

vim.api.nvim_create_autocmd('FileType', {
  pattern = filetypes,
  callback = function(event)
    -- Keep ordinary syntax highlighting available until a parser is installed.
    local started = pcall(vim.treesitter.start, event.buf)
    if not started or vim.api.nvim_get_current_buf() ~= event.buf then
      return
    end

    local lang = vim.treesitter.language.get_lang(event.match)
    local has_folds, query = pcall(vim.treesitter.query.get, lang, 'folds')
    if has_folds and query then
      vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      vim.wo.foldmethod = 'expr'
      vim.wo.foldlevel = 99
    end
  end,
})
