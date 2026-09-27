vim.pack.add({
  {
    src = 'https://github.com/MunifTanjim/nui.nvim',
  },
  {
    src = 'https://github.com/xeluxee/competitest.nvim',
  },
})

local cf_root = '/Users/hxs4018/dev/cf'
local cf_bin = vim.fs.joinpath(cf_root, 'bin')
local function in_cf()
  local cwd = vim.fs.normalize(vim.fn.getcwd())
  return cwd == cf_root or vim.startswith(cwd, cf_root .. '/')
end
if in_cf() then
  vim.fn.mkdir(cf_bin, 'p')
end

local debug_header = vim.api.nvim_get_runtime_file('debug.h', false)[1]
local cpp_args = {
  '-std=c++23',
  '-O2',
  '-Wall',
  '-Wextra',
  '-DLOCAL',
}

if debug_header then
  vim.list_extend(cpp_args, { '-I', vim.fs.dirname(debug_header) })
end

vim.list_extend(cpp_args, {
  '$(FNAME)',
  '-o',
  vim.fs.joinpath(cf_bin, '$(FNOEXT)'),
})

local function problem_filename(task, file_extension)
  local url = (task.url or ''):gsub('[?#].*$', ''):gsub('/+$', '')
  local problem_id

  local codeforces_patterns = {
    '/contest/(%d+)/problem/([^/]+)$',
    '/problemset/problem/(%d+)/([^/]+)$',
    '/gym/(%d+)/problem/([^/]+)$',
  }

  for _, pattern in ipairs(codeforces_patterns) do
    local contest_id, problem_index = url:match(pattern)
    if contest_id then
      problem_id = contest_id .. problem_index
      break
    end
  end

  problem_id = problem_id or url:match('/([^/]+)$')

  if not problem_id or problem_id == '' then
    problem_id = (task.name or ''):match('^%s*([%w_-]+)') or 'problem'
  end

  problem_id = problem_id:gsub('%%(%x%x)', function(hex)
    return string.char(tonumber(hex, 16))
  end)
  problem_id = problem_id:gsub('[^%w._-]', '_')

  return string.format('%s.%s', problem_id, file_extension)
end

require('competitest').setup({
  floating_border = 'rounded',
  runner_ui = {
    interface = 'split',
  },
  split_ui = {
    position = 'right',
    relative_to_editor = true,
    total_width = 0.3,
  },
  start_receiving_persistently_on_setup = in_cf(),
  compile_command = {
    cpp = {
      exec = vim.fn.executable('/opt/homebrew/bin/g++-16') == 1 and '/opt/homebrew/bin/g++-16' or 'g++',
      args = cpp_args,
    },
  },
  run_command = {
    cpp = {
      exec = vim.fs.joinpath(cf_bin, '$(FNOEXT)'),
    },
  },
  maximum_time = 5000,
  output_compare_method = 'squish',
  testcases_directory = '.testcases',
  testcases_use_single_file = false,
  testcases_auto_detect_storage = true,
  template_file = false,
  received_problems_path = function(task, file_extension)
    return vim.fs.joinpath(vim.fn.getcwd(), problem_filename(task, file_extension))
  end,
  received_problems_prompt_path = false,
  received_contests_problems_path = problem_filename,
})

local function show_testcases_without_running(bufnr)
  -- BufEnter work is scheduled; the user may have switched buffers meanwhile.
  if not vim.api.nvim_buf_is_valid(bufnr)
    or not vim.api.nvim_buf_is_loaded(bufnr)
    or vim.api.nvim_get_current_buf() ~= bufnr then
    return
  end

  local filepath = vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))
  if filepath == '' or not vim.startswith(filepath, cf_root .. '/') then
    return
  end

  local commands = require('competitest.commands')
  for runner_bufnr, other_runner in pairs(commands.runners) do
    if runner_bufnr ~= bufnr and other_runner.ui then
      other_runner.ui:hide_ui()
    end
  end

  if commands.runners[bufnr] then
    local source_win = vim.api.nvim_get_current_win()
    local runner = commands.runners[bufnr]
    runner:set_restore_winid(source_win)
    -- show_ui() enters the testcase split; returning here fires BufEnter on
    -- the C++ buffer again. Only reopen the UI when it was actually hidden.
    if not (runner.ui and runner.ui.ui_visible) then
      runner:show_ui()
      if vim.api.nvim_win_is_valid(source_win) then
        vim.api.nvim_set_current_win(source_win)
      end
    end
    return
  end

  local config = require('competitest.config')
  config.load_buffer_config(bufnr)
  local tctbl = require('competitest.testcases').buf_get_testcases(bufnr)
  if not tctbl or next(tctbl) == nil then
    return
  end

  local runner = require('competitest.runner'):new(bufnr)
  if not runner then
    return
  end
  commands.runners[bufnr] = runner

  runner.tcdata = {}
  runner.compile = runner.cc ~= nil
  if runner.compile then
    table.insert(runner.tcdata, {
      stdin = {},
      expout = nil,
      tcnum = 'Compile',
    })
  end

  local tcnums = {}
  for tcnum in pairs(tctbl) do
    table.insert(tcnums, tcnum)
  end
  table.sort(tcnums, function(a, b)
    return tonumber(a) < tonumber(b)
  end)

  for _, tcnum in ipairs(tcnums) do
    local tc = tctbl[tcnum]
    table.insert(runner.tcdata, {
      stdin = vim.split(tc.input, '\n', { plain = true }),
      expout = tc.output and vim.split(tc.output, '\n', { plain = true }),
      tcnum = tcnum,
      timelimit = runner.config.maximum_time,
    })
  end

  for _, tc in ipairs(runner.tcdata) do
    tc.status = ''
    tc.hlgroup = 'CompetiTestRunning'
    tc.stdout = nil
    tc.stderr = nil
    tc.running = false
    tc.killed = false
    tc.time = nil
  end
  runner.next_tc = 1

  vim.api.nvim_create_autocmd('BufUnload', {
    buffer = bufnr,
    once = true,
    callback = function()
      commands.remove_runner(bufnr)
    end,
  })

  local source_win = vim.api.nvim_get_current_win()
  runner:set_restore_winid(source_win)
  runner:show_ui()
  if runner.compile and runner.ui and runner.ui.windows and runner.ui.windows.tc then
    runner.ui.update_testcase = 2
    runner.ui.update_details = true
    runner.ui:update_ui()
    vim.schedule(function()
      local tc_win = runner.ui and runner.ui.windows and runner.ui.windows.tc and runner.ui.windows.tc.winid
      local tc_buf = runner.ui and runner.ui.windows and runner.ui.windows.tc and runner.ui.windows.tc.bufnr
      if tc_win and tc_buf and vim.api.nvim_win_is_valid(tc_win) and vim.api.nvim_buf_line_count(tc_buf) >= 2 then
        vim.api.nvim_win_set_cursor(tc_win, { 2, 0 })
      end
    end)
  end
  if vim.api.nvim_win_is_valid(source_win) then
    vim.api.nvim_set_current_win(source_win)
  end
end

if in_cf() then
  vim.api.nvim_create_autocmd('BufEnter', {
    pattern = '*.cpp',
    callback = function(args)
      vim.schedule(function()
        show_testcases_without_running(args.buf)
      end)
    end,
  })
end

local map = vim.keymap.set

if in_cf() then
  map('n', '<leader>z', '<cmd>CompetiTest run<CR>', {
    desc = 'Run CompetiTest',
  })
end

map('n', '<leader>tr', '<cmd>CompetiTest run<CR>', {
  desc = 'Run testcases',
})

map('n', '<leader>tR', '<cmd>CompetiTest run_no_compile<CR>', {
  desc = 'Run without compiling',
})

map('n', '<leader>ta', '<cmd>CompetiTest add_testcase<CR>', {
  desc = 'Add testcase',
})

map('n', '<leader>te', '<cmd>CompetiTest edit_testcase<CR>', {
  desc = 'Edit testcase',
})

map('n', '<leader>td', '<cmd>CompetiTest delete_testcase<CR>', {
  desc = 'Delete testcase',
})

map('n', '<leader>tt', '<cmd>CompetiTest receive testcases<CR>', {
  desc = 'Receive testcases',
})

map('n', '<leader>tp', '<cmd>CompetiTest receive problem<CR>', {
  desc = 'Receive problem',
})

map('n', '<leader>tc', '<cmd>CompetiTest receive contest<CR>', {
  desc = 'Receive contest',
})

map('n', '<leader>tu', '<cmd>CompetiTest show_ui<CR>', {
  desc = 'Show testcase UI',
})
