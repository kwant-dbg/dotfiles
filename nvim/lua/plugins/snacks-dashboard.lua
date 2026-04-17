return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      local org_roam = require("config.org_roam")
      local pane_gap = 8
      local function pane_width()
        local total_columns = vim.o.columns > 0 and vim.o.columns or 120
        return math.max(40, math.min(60, math.floor((total_columns - pane_gap - 4) / 2)))
      end
      local function truncate_text(text, width)
        if not width or width <= 0 or vim.api.nvim_strwidth(text) <= width then
          return text
        end

        local suffix = "..."
        local target = math.max(0, width - #suffix)
        local truncated = text
        while truncated ~= "" and vim.api.nvim_strwidth(truncated) > target do
          truncated = truncated:sub(1, #truncated - 1)
        end
        return truncated .. suffix
      end
      local function wrap_text(text, width)
        if not text or text == "" or not width or width <= 0 then
          return text
        end

        local lines = {}
        for raw_line in vim.gsplit(text, "\n", { plain = true }) do
          local line = vim.trim(raw_line)
          if line == "" then
            lines[#lines + 1] = ""
          else
            local current = ""
            for word in line:gmatch("%S+") do
              local candidate = current == "" and word or (current .. " " .. word)
              if vim.api.nvim_strwidth(candidate) <= width then
                current = candidate
              else
                if current ~= "" then
                  lines[#lines + 1] = current
                end

                while vim.api.nvim_strwidth(word) > width do
                  local split_at = 0
                  for idx = 1, #word do
                    local chunk = word:sub(1, idx)
                    if vim.api.nvim_strwidth(chunk) > width then
                      break
                    end
                    split_at = idx
                  end
                  split_at = split_at > 0 and split_at or 1
                  lines[#lines + 1] = word:sub(1, split_at)
                  word = word:sub(split_at + 1)
                end

                current = word
              end
            end

            if current ~= "" then
              lines[#lines + 1] = current
            end
          end
        end

        return table.concat(lines, "\n")
      end

      local function agenda_files()
        local ok, config = pcall(require, "orgmode.config")
        local patterns = ok and config.org_agenda_files or { "~/notes/roam/**/*.org" }
        patterns = type(patterns) == "table" and patterns or { patterns }

        local files, seen = {}, {}
        local fs = vim.fs

        local function add_file(file)
          local normalized = vim.fn.fnamemodify(file, ":p")
          if vim.fn.isdirectory(normalized) == 0 and not seen[normalized] then
            seen[normalized] = true
            table.insert(files, normalized)
          end
        end

        for _, pattern in ipairs(patterns) do
          local root_pattern = pattern:match("^(.-)/%*%*")
          local root = root_pattern and vim.fn.expand(root_pattern) or nil
          local expanded = vim.fn.expand(pattern)

          if root and vim.fn.isdirectory(root) == 1 and fs and fs.find then
            for _, file in ipairs(fs.find(function(name)
              return name:sub(-4) == ".org"
            end, { path = root, type = "file", limit = math.huge })) do
              add_file(file)
            end
          else
            for _, file in ipairs(vim.fn.glob(expanded, false, true)) do
              add_file(file)
            end
          end
        end

        table.sort(files, function(a, b)
          local a_mtime = ((vim.uv or vim.loop).fs_stat(a) or {}).mtime
          local b_mtime = ((vim.uv or vim.loop).fs_stat(b) or {}).mtime
          local a_sec = type(a_mtime) == "table" and a_mtime.sec or 0
          local b_sec = type(b_mtime) == "table" and b_mtime.sec or 0
          return a_sec > b_sec
        end)

        return files
      end
      local function collect_org_todos(limit)
        local todos = {}
        local priority_rank = {
          A = 1,
          B = 2,
          C = 3,
        }

        for _, file in ipairs(agenda_files()) do
          local ok, lines = pcall(vim.fn.readfile, file)
          if ok then
            for line_no, line in ipairs(lines) do
              local title = line:match("^%*+%s+TODO%s+(.+)$")
              if title and not title:match(":ARCHIVE:") then
                local priority = title:match("^%[#([A-Z])%]%s*")
                title = title:gsub("%s+:%S+:%s*$", "")
                title = title:gsub("^%[#%u%]%s*", "")
                title = vim.trim(title)
                if title ~= "" and title ~= "%?" then
                  local date
                  local next_line = lines[line_no + 1] or ""
                  date = next_line:match("SCHEDULED:%s*<(%d%d%d%d%-%d%d%-%d%d)")
                    or next_line:match("DEADLINE:%s*<(%d%d%d%d%-%d%d%-%d%d)")
                  todos[#todos + 1] = {
                    file = file,
                    line = line_no,
                    title = title,
                    priority = priority_rank[priority] or math.huge,
                    date = date,
                  }
                end
              end
            end
          end
        end

        table.sort(todos, function(a, b)
          if a.priority ~= b.priority then
            return a.priority < b.priority
          end

          local a_mtime = (((vim.uv or vim.loop).fs_stat(a.file) or {}).mtime or {}).sec or 0
          local b_mtime = (((vim.uv or vim.loop).fs_stat(b.file) or {}).mtime or {}).sec or 0
          if a_mtime ~= b_mtime then
            return a_mtime > b_mtime
          end

          return a.line < b.line
        end)

        if #todos > limit then
          while #todos > limit do
            table.remove(todos)
          end
        end

        return todos
      end
      local function has_org_todos()
        return #collect_org_todos(1) > 0
      end
      local function oldfiles_iter(filter_root)
        local dashboard = require("snacks.dashboard")
        if filter_root then
          return dashboard.oldfiles({ filter = { [filter_root] = true } })
        end
        return dashboard.oldfiles()
      end
      local notes_root = vim.fs.normalize(vim.fn.expand("~/notes"))
      local function path_is_under(path, root)
        local normalized = vim.fs.normalize(path)
        return normalized == root or normalized:sub(1, #root + 1) == root .. "/"
      end
      local function project_filter(dir)
        return not path_is_under(dir, notes_root)
      end
      local function recent_projects(limit)
        local dirs = {}
        local seen = {}

        for file in oldfiles_iter() do
          local dir = Snacks.git.get_root(file)
          if dir and not seen[dir] and project_filter(dir) then
            seen[dir] = true
            dirs[#dirs + 1] = dir
            if #dirs >= limit then
              break
            end
          end
        end

        return dirs
      end
      local function project_display_name(dir, duplicates)
        local name = vim.fn.fnamemodify(dir, ":t")
        if (duplicates[name] or 0) > 1 then
          local parent = vim.fn.fnamemodify(dir, ":h:t")
          name = ("%s (%s)"):format(name, parent)
        end
        return name
      end
      -- Direct assignment avoids vim.tbl_deep_extend merging arrays by index,
      -- which caused LazyVim's 9 preset keys to bleed into the user's 8 keys.
      local function heading(title, pane, extra)
        return vim.tbl_extend("force", {
          pane = pane,
          align = "center",
          text = {
            { title, hl = "SnacksDashboardTitle" },
          },
        }, extra or {})
      end
      local function todo_section(limit, pane)
        return function()
          local todos = collect_org_todos(limit)
          if #todos == 0 then
            return nil
          end

          local items = {}
          for _, todo in ipairs(todos) do
            items[#items + 1] = {
              pane = pane,
              indent = 2,
              icon = " ",
              desc = todo.title,
              label = todo.date and (" " .. todo.date) or nil,
              autokey = true,
              action = function()
                vim.cmd.edit(vim.fn.fnameescape(todo.file))
                vim.api.nvim_win_set_cursor(0, { todo.line, 0 })
                vim.cmd("normal! zz")
              end,
            }
          end
          return items
        end
      end
      local function notes_section(pane)
        return {
          {
            pane = pane,
            indent = 2,
            align = "left",
            icon = " ",
            key = "d",
            desc = "Today's note",
            label = os.date("%Y-%m-%d"),
            action = function()
              org_roam.open_today_daily_note()
            end,
          },
        }
      end
      local function register_projects_section()
        require("snacks.dashboard").sections.trip_projects = function(item)
          local dirs = recent_projects(item.limit or 4)
          if #dirs == 0 then
            return nil
          end

          local duplicates = {}
          local width = pane_width()
          for _, dir in ipairs(dirs) do
            local name = vim.fn.fnamemodify(dir, ":t")
            duplicates[name] = (duplicates[name] or 0) + 1
          end

          local project_keys = { "p", "o", "i", "u" }
          local items = {}
          for idx, dir in ipairs(dirs) do
            items[#items + 1] = {
              indent = 2,
              align = "left",
              icon = " ",
              desc = truncate_text(project_display_name(dir, duplicates), math.max(18, width - 8)),
              key = project_keys[idx],
              action = function(self)
                vim.fn.chdir(dir)
                local dashboard = require("snacks.dashboard")
                local session = dashboard.sections.session()
                if session then
                  local session_loaded = false
                  vim.api.nvim_create_autocmd("SessionLoadPost", {
                    once = true,
                    callback = function()
                      session_loaded = true
                    end,
                  })
                  vim.defer_fn(function()
                    if not session_loaded then
                      dashboard.pick()
                    end
                  end, 100)
                  return self:action(session.action)
                end
                dashboard.pick()
              end,
            }
          end

          return items
        end
      end
      local function shorten_path(path, limit)
        local display = vim.fn.fnamemodify(path, ":~")
        if vim.api.nvim_strwidth(display) > limit then
          display = vim.fn.pathshorten(display)
        end
        return truncate_text(display, limit)
      end
      local function workspace()
        return function()
          local width = pane_width()
          local cwd = (vim.uv or vim.loop).cwd() or vim.fn.getcwd()
          local git_root = Snacks.git.get_root(cwd)
          local root = git_root or cwd
          local items = {
            {
              pane = 1,
              align = "center",
              text = {
                {
                  shorten_path(root, width),
                  hl = "SnacksDashboardDesc",
                  align = "center",
                  width = width,
                },
              },
            },
          }
          if git_root then
            local branch = vim.fn.systemlist({ "git", "-C", root, "branch", "--show-current" })[1]
            if vim.v.shell_error == 0 and branch and branch ~= "" then
              items[#items + 1] = {
                pane = 1,
                align = "center",
                text = {
                  {
                    truncate_text(" " .. branch, width),
                    hl = "SnacksDashboardKey",
                    align = "center",
                    width = width,
                  },
                },
              }
            end
          end

          items[#items].padding = { 2, 0 }
          return items
        end
      end

      opts.terminal = {
        win = { wo = { winbar = "" } },
        auto_insert = false,
      }

      opts.indent = {
        enabled = true,
        indent = { enabled = false },
        scope  = { enabled = true },
      }

      opts.dashboard = {
        config = function(self)
          self.width = pane_width()
          register_projects_section()
        end,
        width = pane_width(),
        pane_gap = pane_gap,
        preset = {
          pick = function(cmd, pick_opts)
            return LazyVim.pick(cmd, pick_opts)()
          end,
          header = [[
███╗   ██╗██╗   ██╗██╗███╗   ███╗
████╗  ██║██║   ██║██║████╗ ████║
██╔██╗ ██║██║   ██║██║██╔████╔██║
██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝
          ]],
          keys = {
            { icon = " ", key = "d", desc = "Today's note", action = function() org_roam.open_today_daily_note() end },
            { icon = " ", key = "f", desc = "Find files", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "g", desc = "Live grep", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Recent files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = " ", key = "e", desc = "File explorer", action = ":Neotree toggle" },
            { icon = " ", key = "c", desc = "Edit config", action = ":lua Snacks.dashboard.pick('files', { cwd = vim.fn.stdpath('config') })" },
            { icon = " ", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        formats = {
          icon = function(item)
            if item.file and (item.icon == "file" or item.icon == "directory") then
              return Snacks.dashboard.icon(item.file, item.icon)
            end
            return { { item.icon, width = 2, hl = "SnacksDashboardIcon" }, { " ", hl = "SnacksDashboardNormal" } }
          end,
          header = { "%s", align = "center", hl = "SnacksDashboardHeader" },
          title = { "%s", align = "left", hl = "SnacksDashboardTitle" },
          desc = function(item, ctx)
            local label_width = item.label and vim.api.nvim_strwidth(tostring(item.label)) or 0
            local key_width = item.key and (vim.api.nvim_strwidth(tostring(item.key)) + 2) or 0
            local width = math.max(0, (ctx.width or 0) - label_width - key_width - 1)
            return { wrap_text(item.desc, width), width = width, hl = "SnacksDashboardDesc" }
          end,
          key = function(item)
            return {
              { "[", hl = "SnacksDashboardSpecial" },
              { item.key, hl = "SnacksDashboardKey" },
              { "]", hl = "SnacksDashboardSpecial" },
            }
          end,
          footer = { "%s", align = "center", hl = "SnacksDashboardFooter" },
        },
        sections = {
          { section = "header", padding = { 1, 2 }, width = 2 * pane_width() + pane_gap },
          workspace(),
          -- Pane 1: Notes, Todo
          {
            pane = 1,
            indent = 2,
            align = "left",
            icon = " ",
            key = "s",
            desc = "Continue last session",
            action = function()
              require("persistence").load({ last = true })
            end,
          },
          notes_section(1),
          heading("Todo", 1, { padding = { 0, 1 }, enabled = has_org_todos }),
          todo_section(10, 1),
          -- Pane 2: Recent Files, Projects
          heading("Recent Files", 2),
          { pane = 2, section = "recent_files", limit = 5, indent = 2 },
          heading("Projects", 2, { padding = { 0, 1 } }),
          { pane = 2, section = "trip_projects", limit = 4 },
          { section = "startup", padding = { 1, 0 }, align = "center", width = 2 * pane_width() + pane_gap },
        },
      }
    end,
    init = function()
      local group = vim.api.nvim_create_augroup("trip_snacks_dashboard", { clear = true })

      local function set_dashboard_highlights()
        local set = vim.api.nvim_set_hl
        set(0, "SnacksDashboardNormal", { fg = "#c5c9c5", bg = "#181616" })
        set(0, "SnacksDashboardHeader", { fg = "#7e9cd8", bold = true })
        set(0, "SnacksDashboardTitle", { fg = "#c4b28a", bold = true })
        set(0, "SnacksDashboardIcon", { fg = "#7fb4ca" })
        set(0, "SnacksDashboardDesc", { fg = "#a6a69c" })
        set(0, "SnacksDashboardKey", { fg = "#87a987", bold = true })
        set(0, "SnacksDashboardSpecial", { fg = "#b6927b" })
        set(0, "SnacksDashboardFooter", { fg = "#93836c", italic = true })
        set(0, "SnacksDashboardMuted", { fg = "#727169" })
        set(0, "SnacksDashboardDir", { fg = "#727169" })
        set(0, "SnacksDashboardFile", { fg = "#dcd7ba" })
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = set_dashboard_highlights,
      })

      set_dashboard_highlights()
    end,
  },
}
