-- Shared diagnostics appearance.

vim.diagnostic.config({
    virtual_text = {
      spacing = 2,
      prefix = '●',
    },
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = {
      border = 'rounded',
      source = true,
    },
})

vim.api.nvim_create_user_command('LspInfo', function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })

  if #clients == 0 then
    vim.notify('No language server attached to this buffer')
    return
  end

  local lines = { 'Language servers attached to this buffer:' }

  for _, client in ipairs(clients) do
    local command = client.config.cmd
    command = type(command) == 'table' and table.concat(command, ' ') or tostring(command)

    lines[#lines + 1] = string.format(
      '\n%s\n  command: %s\n  root: %s',
      client.name,
      command,
      client.config.root_dir or 'single file'
    )
  end

  vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO, {
    title = 'LSP information',
  })
end, {
  desc = 'Show language servers attached to the current buffer',
})

local has_blink, blink = pcall(require, 'blink.cmp')

local function enable(name, config)
  if vim.fn.executable(config.cmd[1]) ~= 1 then
    return
  end

  if has_blink then
    config.capabilities = blink.get_lsp_capabilities(config.capabilities)
  end

  vim.lsp.config(name, config)
  vim.lsp.enable(name)
end

enable('gopls', {
  cmd = { 'gopls' },
  filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
  root_markers = { 'go.work', 'go.mod', '.git' },
  settings = {
    gopls = {
      staticcheck = true,
      usePlaceholders = true,
    },
  },
})

enable('clangd', {
  cmd = {
    'clangd',
    '--query-driver=/opt/homebrew/bin/g++-16',
  },
  filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
  root_markers = {
    '.clangd',
    'compile_commands.json',
    'compile_flags.txt',
    '.git',
  },
})

enable('pyright', {
  cmd = { 'pyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = {
    'pyrightconfig.json',
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt',
    'Pipfile',
    '.git',
  },
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = 'openFilesOnly',
        useLibraryCodeForTypes = true,
      },
    },
  },
})

enable('ruff', {
  cmd = { 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = {
    'pyproject.toml',
    'ruff.toml',
    '.ruff.toml',
    '.git',
  },
})

enable('yamlls', {
  cmd = { 'yaml-language-server', '--stdio' },
  filetypes = { 'yaml', 'yaml.docker-compose', 'yaml.gitlab' },
  root_markers = { '.git' },
  settings = {
    yaml = {
      validate = true,
      hover = true,
      completion = true,
      format = { enable = true },

      -- Keep schema resolution local unless a project explicitly provides one.
      schemaStore = {
        enable = false,
        url = '',
      },
      kubernetesCRDStore = {
        enable = false,
      },
    },
  },
})

enable('terraformls', {
  cmd = { 'terraform-ls', 'serve' },
  filetypes = { 'terraform', 'terraform-vars' },
  root_markers = { '.terraform', '.git' },
})

enable('lua_ls', {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.luarc.jsonc', '.git' },
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
})

local function format_buffer(bufnr)
  if vim.bo[bufnr].filetype == 'lua' and vim.fn.executable('stylua') == 1 then
    local file = vim.api.nvim_buf_get_name(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local input = table.concat(lines, '\n')

    if vim.bo[bufnr].endofline then
      input = input .. '\n'
    end

    local command = { 'stylua' }
    if file ~= '' then
      vim.list_extend(command, { '--stdin-filepath', file })
    end
    command[#command + 1] = '-'

    local result = vim.system(command, { stdin = input, text = true }):wait()
    if result.code ~= 0 then
      vim.notify(result.stderr or 'StyLua failed', vim.log.levels.ERROR)
      return
    end

    local formatted = vim.split(result.stdout or '', '\n', { plain = true })
    if formatted[#formatted] == '' then
      table.remove(formatted)
    end
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)
    return
  end

  vim.lsp.buf.format({
    bufnr = bufnr,
    async = false,
    timeout_ms = 5000,
  })
end

-- These mappings exist only in buffers with an attached language server.

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)

    -- Blink owns completion when available; keep native LSP completion as a fallback.
    if not has_blink and client and client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, event.buf, {
        autotrigger = true,
      })
    end
    if client and client:supports_method('textDocument/inlayHint') then
      vim.keymap.set('n', '<leader>ch', function()
        local filter = { bufnr = event.buf }
        local enabled = vim.lsp.inlay_hint.is_enabled(filter)

        vim.lsp.inlay_hint.enable(not enabled, filter)
      end, {
        buffer = event.buf,
        desc = 'Toggle inlay hints',
      })
    end

    local function opts(description)
      return {
        buffer = event.buf,
        desc = description,
      }
    end

    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts('Go to definition'))
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts('Go to declaration'))
    vim.keymap.set('n', '<leader>cf', function()
      format_buffer(event.buf)
    end, opts('Format file'))

    vim.keymap.set('n', '<leader>cd', vim.diagnostic.open_float, opts('Line diagnostics'))

    vim.keymap.set('n', ']d', function()
      vim.diagnostic.jump({ count = 1, float = true })
    end, opts('Next diagnostic'))

    vim.keymap.set('n', '[d', function()
      vim.diagnostic.jump({ count = -1, float = true })
    end, opts('Previous diagnostic'))
  end,
})
