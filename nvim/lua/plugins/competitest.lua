return {
  "xeluxee/competitest.nvim",
  enabled = false,
  dependencies = { "MunifTanjim/nui.nvim" },
  cmd = { "CompetiTest" },
  keys = {
    { "<leader>cr", "<cmd>CompetiTest run<cr>",             desc = "CP: Run testcases" },
    { "<leader>ca", "<cmd>CompetiTest add_testcase<cr>",    desc = "CP: Add testcase" },
    { "<leader>ce", "<cmd>CompetiTest edit_testcase<cr>",   desc = "CP: Edit testcase" },
    { "<leader>cd", "<cmd>CompetiTest delete_testcase<cr>", desc = "CP: Delete testcase" },
    { "<leader>cx", "<cmd>CompetiTest receive problem<cr>", desc = "CP: Fetch from browser" },
    { "<leader>cX", "<cmd>CompetiTest receive contest<cr>", desc = "CP: Fetch contest" },
  },
  opts = {
    compile_command = {
      cpp = {
        exec = "g++",
        args = { "-std=c++17", "-O2", "-Dlocal", "-Wall", "-I" .. vim.fn.expand("~/dev/cf"), "$(FNAME)", "-o", "$(FNOEXT)" },
      },
    },
    run_command = {
      cpp = { exec = "./$(FNOEXT)" },
    },
    receive_print_message = true,
    testcases_use_single_file = false,
    open_ui_if_every_test_passed = true,
    runner_ui = {
      interface = "split",
    },
    split_ui = {
      position = "bottom",
      relative_to_editor = true,
      total_height = 0.35,
      horizontal_layout = {
        { 1, "tc" },
        { 2, "si" },
        { 2, "so" },
        { 2, "eo" },
      },
    },
    received_files_extension = "cpp",
    testcases_directory = ".tc",
    received_problems_path = function(task, file_extension)
      local contest, problem = task.url:match("/contest/(%d+)/problem/(%a+)")
      if contest and problem then
        return vim.fn.getcwd() .. "/" .. contest .. problem .. "." .. file_extension
      end
      -- fallback for non-CF URLs
      return vim.fn.getcwd() .. "/" .. task.name:gsub("[^%w]", "_") .. "." .. file_extension
    end,
    -- WSL2: use a non-conflicting port
    companion_port = 10045,
  },
}
