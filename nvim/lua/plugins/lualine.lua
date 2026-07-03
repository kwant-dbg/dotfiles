local function safe_require(name)
  local ok, mod = pcall(require, name)
  return ok and mod or nil
end

local palette = require("config.palette")

local mode_map = {
  n = { "󰊠", "N", palette.bg_dark, palette.green_soft },
  no = { "󰆕", "O", palette.bg_dark, palette.green_soft },
  nov = { "󰆕", "O", palette.bg_dark, palette.green_soft },
  noV = { "󰆕", "O", palette.bg_dark, palette.green_soft },
  ["no\22"] = { "󰆕", "O", palette.bg_dark, palette.green_soft },
  niI = { "󰊠", "N", palette.bg_dark, palette.green_soft },
  niR = { "󰊠", "N", palette.bg_dark, palette.green_soft },
  niV = { "󰊠", "N", palette.bg_dark, palette.green_soft },
  nt = { "󰊠", "N", palette.bg_dark, palette.green_soft },
  v = { "󰈈", "V", palette.bg_dark, palette.purple_muted },
  V = { "󰈈", "VL", palette.bg_dark, palette.purple_muted },
  ["\22"] = { "󰈈", "VB", palette.bg_dark, palette.purple_muted },
  s = { "󰒅", "S", palette.bg_dark, palette.pink_soft },
  S = { "󰒅", "SL", palette.bg_dark, palette.pink_soft },
  ["\19"] = { "󰒅", "SB", palette.bg_dark, palette.pink_soft },
  i = { "󰏫", "I", palette.bg_dark, palette.blue_soft },
  ic = { "󰏫", "I", palette.bg_dark, palette.blue_soft },
  ix = { "󰏫", "I", palette.bg_dark, palette.blue_soft },
  R = { "󰑕", "R", palette.bg_dark, palette.red_soft },
  Rc = { "󰑕", "R", palette.bg_dark, palette.red_soft },
  Rx = { "󰑕", "R", palette.bg_dark, palette.red_soft },
  Rv = { "󰑕", "VR", palette.bg_dark, palette.red_soft },
  Rvc = { "󰑕", "VR", palette.bg_dark, palette.red_soft },
  Rvx = { "󰑕", "VR", palette.bg_dark, palette.red_soft },
  c = { "", "C", palette.bg_dark, palette.yellow_muted },
  cv = { "", "EX", palette.bg_dark, palette.yellow_muted },
  r = { "󰭎", "P", palette.bg_dark, palette.orange_soft },
  rm = { "󰭎", "M", palette.bg_dark, palette.orange_soft },
  ["r?"] = { "󰭎", "?", palette.bg_dark, palette.orange_soft },
  ["!"] = { "", "SH", palette.bg_dark, palette.cyan_muted },
  t = { "", "T", palette.bg_dark, palette.cyan_muted },
}

local function mode_info()
  local mode = vim.fn.mode()
  if mode == "n" and vim.bo.buftype == "terminal" then
    return { "", "T", palette.fg_terminal_dark, palette.cyan_muted }
  end

  return mode_map[mode] or { "󰘳", mode:upper(), palette.fg_terminal_dark, palette.fg }
end

local function mode_name()
  local mode = mode_info()
  return mode[2]
end

local function mode_color()
  local mode = mode_info()
  return { fg = mode[3], bg = mode[4], gui = "bold" }
end

local root_cache = {
  cwd = nil,
  name = nil,
}

local function project_name()
  local cwd = vim.fn.getcwd()
  if root_cache.cwd == cwd then
    return root_cache.name
  end

  local root = vim.fs.root(0, { ".git", "lua", "package.json", "pyproject.toml", "Cargo.toml", "go.mod" }) or cwd
  root_cache.cwd = cwd
  root_cache.name = vim.fn.fnamemodify(root, ":t")
  return root_cache.name
end

local function sidekick_state()
  local sidekick = safe_require("sidekick.status")
  if not sidekick then
    return nil
  end
  return sidekick.get()
end

local function sidekick_cli()
  local sidekick = safe_require("sidekick.status")
  if not sidekick then
    return {}
  end
  return sidekick.cli()
end

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        globalstatus = true,
        refresh = {
          statusline = 250,
          tabline = 1000,
          winbar = 1000,
        },
      })

      opts.sections = opts.sections or {}

      opts.sections.lualine_a = {
        {
          mode_name,
          color = mode_color,
          padding = { left = 1, right = 1 },
        },
      }

      opts.sections.lualine_b = {
        {
          project_name,
          icon = "󰉋",
          color = { fg = palette.green_soft },
        },
        {
          "branch",
          icon = "",
          color = { fg = palette.blue_soft },
        },
        {
          "diff",
          symbols = { added = " ", modified = " ", removed = " " },
          colored = true,
        },
      }

      opts.sections.lualine_c = {
        {
          "filename",
          path = 1,
          symbols = {
            modified = " ●",
            readonly = " ",
            unnamed = "[No Name]",
            newfile = "[New]",
          },
        },
        {
          function()
            return "●"
          end,
          color = function()
            local state = sidekick_state()
            if not state then
              return nil
            end
            if state.kind == "Error" then
              return "DiagnosticError"
            end
            return state.busy and "DiagnosticWarn" or "Special"
          end,
          cond = function()
            return sidekick_state() ~= nil
          end,
        },
      }

      opts.sections.lualine_x = {
        {
          "diagnostics",
          sources = { "nvim_lsp", "nvim_diagnostic" },
          symbols = { error = " ", warn = " ", info = " ", hint = " " },
        },
        {
          function()
            local clients = vim.lsp.get_clients({ bufnr = 0 })
            if #clients == 0 then
              return ""
            end

            local names = {}
            for _, client in ipairs(clients) do
              table.insert(names, client.name)
            end
            table.sort(names)
            return table.concat(names, ",")
          end,
          icon = "",
          cond = function()
            return #vim.lsp.get_clients({ bufnr = 0 }) > 0
          end,
          color = { fg = palette.yellow_muted },
        },
        {
          function()
            return "@" .. vim.fn.reg_recording()
          end,
          cond = function()
            return vim.fn.reg_recording() ~= ""
          end,
          color = "DiagnosticWarn",
        },
        {
          "searchcount",
          maxcount = 999,
          timeout = 500,
        },
        {
          function()
            local cli = sidekick_cli()
            return " " .. (#cli > 1 and #cli or "")
          end,
          cond = function()
            return #sidekick_cli() > 0
          end,
          color = function()
            return "Special"
          end,
        },
      }

      opts.sections.lualine_y = {
        { "filetype", icon_only = false },
      }

      opts.sections.lualine_z = {}

      opts.inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {
          {
            "filename",
            path = 1,
            symbols = { modified = " ●", readonly = " ", unnamed = "[No Name]" },
          },
        },
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      }

      return opts
    end,
  },
}
