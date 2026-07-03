return {
  {
    "nvim-orgmode/orgmode",
    tag = "0.7.0",
    event = "VeryLazy",
    ft = "org",
    config = function()
      local palette = require("config.palette")

      function _G.TripOrgIndent()
        local line = vim.fn.getline(vim.v.lnum)
        local heading = line:match("^%s*(%*+)%s")

        if heading then
          return (#heading - 1) * 4
        end

        local previous_lnum = vim.v.lnum - 1

        if previous_lnum < 1 then
          return 0
        end

        local previous = vim.fn.getline(previous_lnum)
        local previous_heading = previous:match("^%s*(%*+)%s")

        if previous_heading then
          return #previous_heading * 4
        end

        return vim.fn.indent(previous_lnum)
      end

      local function normalize_org_heading_line()
        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        local line = vim.api.nvim_get_current_line()
        local stars, rest = line:match("^%s*(%*+)(%s.*)$")

        if not stars then
          return
        end

        local indent = string.rep(" ", (#stars - 1) * 4)
        local normalized = indent .. stars .. rest

        if line == normalized then
          return
        end

        vim.api.nvim_set_current_line(normalized)
        vim.api.nvim_win_set_cursor(0, { row, math.max(0, col + #normalized - #line) })
      end

      require("orgmode").setup({
        org_agenda_files = { "~/notes/roam/**/*.org" },
        org_default_notes_file = "~/notes/roam/inbox.org",
        org_hide_emphasis_markers = true,
        org_hide_leading_stars = false,
        org_startup_indented = true,
        org_adapt_indentation = true,
        org_indent_mode_turns_off_org_adapt_indentation = false,
        org_startup_folded = "showeverything",
        org_ellipsis = " ▾",
        org_todo_keyword_faces = {
          TODO = ":foreground " .. palette.red_soft .. " :weight bold",
          DONE = ":foreground " .. palette.green_soft .. " :weight bold",
        },
        mappings = {
          disable_all = true,
          capture = {
            org_capture_finalize = "<C-c><C-c>",
            org_capture_kill = "<C-c><C-k>",
          },
        },
      })

      local function apply_org_highlights()
        -- Heading colors matching kanagawa dragon (same as Doom config)
        vim.api.nvim_set_hl(0, "@org.headline.level1", { fg = palette.yellow_soft, bold = true, nocombine = true })
        vim.api.nvim_set_hl(0, "@org.headline.level2", { fg = palette.blue_soft, bold = true, nocombine = true })
        vim.api.nvim_set_hl(0, "@org.headline.level3", { fg = palette.green_soft, bold = true, nocombine = true })
        vim.api.nvim_set_hl(0, "@org.headline.level4", { fg = palette.purple_soft, bold = true, nocombine = true })
        vim.api.nvim_set_hl(0, "@org.headline.level5", { fg = palette.yellow_muted, bold = true, nocombine = true })
        vim.api.nvim_set_hl(0, "@org.headline.level6", { fg = palette.green_soft, bold = true, nocombine = true })
        vim.api.nvim_set_hl(0, "@org.headline.level7", { fg = palette.cyan_muted, bold = true, nocombine = true })
        vim.api.nvim_set_hl(0, "@org.headline.level8", { fg = palette.purple_muted, bold = true, nocombine = true })

        -- Emphasis faces
        vim.api.nvim_set_hl(0, "@org.bold", { fg = palette.red_soft, bold = true })
        vim.api.nvim_set_hl(0, "@org.italic", { fg = palette.cyan_muted, italic = true })
        vim.api.nvim_set_hl(0, "@org.underline", { fg = palette.cyan_soft, underline = true })
        vim.api.nvim_set_hl(0, "@org.code", { fg = palette.yellow_muted, bg = palette.bg_code })
        vim.api.nvim_set_hl(0, "@org.verbatim", { fg = palette.green_soft, bg = palette.bg_code })
        vim.api.nvim_set_hl(0, "@org.strikethrough", { fg = palette.muted_deep, strikethrough = true })

        vim.api.nvim_set_hl(0, "TripOrgHeadlineStar1", { fg = palette.yellow_soft, bold = true, nocombine = true })
        vim.api.nvim_set_hl(0, "TripOrgHeadlineStar2", { fg = palette.blue_soft, bold = true, nocombine = true })
        vim.api.nvim_set_hl(0, "TripOrgHeadlineStar3", { fg = palette.green_soft, bold = true, nocombine = true })
        vim.api.nvim_set_hl(0, "TripOrgHeadline2", { fg = palette.blue_soft, bold = true, nocombine = true })
        vim.api.nvim_set_hl(0, "TripOrgHeadline3", { fg = palette.green_soft, bold = true, nocombine = true })
      end

      local headline_ns = vim.api.nvim_create_namespace("trip_org_heading_highlights")

      local function apply_org_heading_highlight(bufnr, line_nr)
        if not vim.api.nvim_buf_is_loaded(bufnr) then
          return
        end

        vim.api.nvim_buf_clear_namespace(bufnr, headline_ns, line_nr, line_nr + 1)

        local line = vim.api.nvim_buf_get_lines(bufnr, line_nr, line_nr + 1, false)[1]
        if not line then
          return
        end

        local hl_group = line:match("^%s*%*%*%*%s") and "TripOrgHeadline3"
          or line:match("^%s*%*%*%s") and "TripOrgHeadline2"

        if hl_group then
          vim.api.nvim_buf_set_extmark(bufnr, headline_ns, line_nr, 0, {
            end_col = #line,
            hl_group = hl_group,
            priority = 200,
          })
        end
      end

      local function apply_buffer_org_heading_highlights(bufnr)
        if not vim.api.nvim_buf_is_loaded(bufnr) then
          return
        end

        vim.api.nvim_buf_clear_namespace(bufnr, headline_ns, 0, -1)

        for line_nr, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
          local hl_group = line:match("^%s*%*%*%*%s") and "TripOrgHeadline3"
            or line:match("^%s*%*%*%s") and "TripOrgHeadline2"

          if hl_group then
            vim.api.nvim_buf_set_extmark(bufnr, headline_ns, line_nr - 1, 0, {
              end_col = #line,
              hl_group = hl_group,
              priority = 200,
            })
          end
        end
      end

      apply_org_highlights()

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = apply_org_highlights,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "org",
        callback = function()
          vim.opt_local.conceallevel = 2
          vim.opt_local.concealcursor = "nc"
          vim.opt_local.comments = ""
          vim.opt_local.autoindent = true
          vim.opt_local.smartindent = false
          vim.opt_local.indentexpr = "v:lua.TripOrgIndent()"
          vim.cmd([[
            silent! syntax clear TripOrgHeadlineStar1
            silent! syntax clear TripOrgHeadlineStar2
            silent! syntax clear TripOrgHeadlineStar3
            silent! syntax clear TripOrgHeadline2
            silent! syntax clear TripOrgHeadline3
            syntax match TripOrgHeadlineStar1 /^\s*\zs\*\ze\s/ conceal cchar=◉
            syntax match TripOrgHeadlineStar2 /^\s*\zs\*\{2}\ze\s/ conceal cchar=◆
            syntax match TripOrgHeadlineStar3 /^\s*\zs\*\{3}\ze\s/ conceal cchar=▸
          ]])
          local indent_group = vim.api.nvim_create_augroup("trip_org_indent", { clear = false })
          local heading_group = vim.api.nvim_create_augroup("trip_org_heading_highlights", { clear = false })
          local bufnr = vim.api.nvim_get_current_buf()

          apply_buffer_org_heading_highlights(bufnr)
          vim.api.nvim_clear_autocmds({ group = heading_group, buffer = bufnr })
          vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
            group = heading_group,
            buffer = bufnr,
            callback = function()
              apply_buffer_org_heading_highlights(bufnr)
            end,
          })
          vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
            group = heading_group,
            buffer = bufnr,
            callback = function()
              apply_org_heading_highlight(bufnr, vim.api.nvim_win_get_cursor(0)[1] - 1)
            end,
          })

          vim.keymap.set("n", "cit", function()
            require("orgmode").action("org_mappings.todo_next_state")
          end, { buffer = true, desc = "Cycle TODO state" })
          vim.keymap.set("i", "<CR>", function()
            if vim.api.nvim_get_current_line():match("^%s*%*+%s") then
              return "<Esc>==o"
            end

            return "<CR>"
          end, { buffer = true, expr = true, desc = "Org newline" })
          vim.keymap.set("i", "<Space>", function()
            if vim.api.nvim_get_current_line():sub(1, vim.fn.col(".") - 1):match("^%s*%*+$") then
              return " <Esc>==A"
            end

            return " "
          end, { buffer = true, expr = true, desc = "Org heading space" })
          vim.api.nvim_clear_autocmds({ group = indent_group, buffer = bufnr })
          vim.api.nvim_create_autocmd("InsertLeave", {
            group = indent_group,
            buffer = bufnr,
            callback = normalize_org_heading_line,
          })
        end,
      })
    end,
  },
  {
    "akinsho/org-bullets.nvim",
    event = "VeryLazy",
    ft = "org",
    config = function()
      require("org-bullets").setup({
        concealcursor = true,
        symbols = {
          headlines = false,
          checkboxes = {
            half = { "", "OrgTSCheckboxHalfChecked" },
            done = { "✓", "OrgDone" },
            todo = { "☐", "OrgTODO" },
          },
        },
      })
    end,
  },
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        per_filetype = {
          org = { "orgmode", "buffer", "path" },
        },
        providers = {
          orgmode = {
            name = "Orgmode",
            module = "orgmode.org.autocompletion.blink",
            fallbacks = { "buffer" },
          },
        },
      },
    },
  },
  {
    "chipsenkbeil/org-roam.nvim",
    tag = "0.2.0",
    event = "VeryLazy",
    dependencies = { "nvim-orgmode/orgmode" },
    config = function()
      local org_roam = require("config.org_roam")

      require("org-roam").setup({
        directory = "~/notes/roam",
        bindings = false,
        extensions = {
          dailies = {
            directory = "daily",
            templates = org_roam.daily_note_templates(),
          },
        },
        templates = {
          p = {
            description = "Permanent note",
            template = "\n\n* Related Notes\n- %?",
            target = "permanent/%[slug].org",
            header = "#+title: ${title}\n#+filetags: :permanent:\n#+date: %<%Y-%m-%d>\n",
          },
          m = {
            description = "Meeting",
            template = "* Notes\n%?\n\n* Action Items\n- [ ] \n\n* Related\n- ",
            target = "meetings/%<%Y-%m-%d> - %[slug].org",
            header = "#+title: ${title}\n#+filetags: :meeting:\n#+date: %<%Y-%m-%d>\n",
          },
        },
      })

      local roam = require("org-roam")

      require("which-key").add({ { "<leader>r", group = "org-roam" } })

      vim.keymap.set("n", "<leader>ra", function()
        require("orgmode").action("agenda.prompt")
      end, { desc = "Org agenda" })
      vim.keymap.set("n", "<leader>rf", function()
        roam.api.find_node()
      end, { desc = "Find node" })
      vim.keymap.set("n", "<leader>ri", function()
        roam.api.insert_node()
      end, { desc = "Insert node link" })
      vim.keymap.set("n", "<leader>rb", function()
        roam.ui.toggle_node_buffer()
      end, { desc = "Toggle backlinks" })
      vim.keymap.set("n", "<leader>rd", function()
        org_roam.open_today_daily_note()
      end, { desc = "Open today's note" })

      vim.api.nvim_create_autocmd("BufWritePost", {
        group = vim.api.nvim_create_augroup("trip_org_roam_sync", { clear = true }),
        pattern = "*.org",
        callback = function()
          local path = vim.fn.expand("%:p")
          local notes_dir = vim.fs.normalize(vim.fn.expand("~/notes/roam"))

          if not vim.startswith(vim.fs.normalize(path), notes_dir .. "/") then
            return
          end

          local ok, roam = pcall(require, "org-roam")
          if ok then
            pcall(function()
              roam.database:load_file({ path = path, force = true }):wait()
            end)
          end

          if vim.fn.executable("emacsclient") == 1 then
            local escaped_path = path:gsub("\\", "\\\\"):gsub('"', '\\"')

            vim.fn.jobstart({
              "emacsclient",
              "--no-wait",
              "--eval",
              string.format('(progn (org-roam-db-update-file "%s") (org-roam-ui--send-graphdata))', escaped_path),
            }, { detach = true })
          end
        end,
      })

      local group = vim.api.nvim_create_augroup("trip_org_roam_daily", { clear = true })

      vim.api.nvim_create_autocmd("VimEnter", {
        group = group,
        once = true,
        callback = function()
          if #vim.api.nvim_list_uis() == 0 then
            return
          end

          pcall(org_roam.ensure_daily_note)
        end,
      })
    end,
  },
  {
    "nvim-orgmode/telescope-orgmode.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-orgmode/orgmode",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("telescope").load_extension("orgmode")

      local ext = require("telescope").extensions.orgmode

      vim.keymap.set("n", "<leader>rs", function()
        ext.search_headings()
      end, { desc = "Search headings" })
      vim.keymap.set("n", "<leader>rr", function()
        ext.refile_heading()
      end, { desc = "Refile heading" })
    end,
  },
}
