return {
  {
    "nvim-orgmode/orgmode",
    tag = "0.7.0",
    event = "VeryLazy",
    config = function()
      require("orgmode").setup({
        org_agenda_files = { "~/notes/roam/**/*.org" },
        org_default_notes_file = "~/notes/roam/inbox.org",
        org_hide_emphasis_markers = true,
        org_hide_leading_stars = true,
        org_startup_indented = true,
        org_startup_folded = "showeverything",
        org_ellipsis = " ▾",
        org_todo_keyword_faces = {
          TODO = ":foreground #c4746e :weight bold",
          DONE = ":foreground #87a987 :weight bold",
        },
        mappings = {
          disable_all = true,
          capture = {
            org_capture_finalize = "<C-c><C-c>",
            org_capture_kill = "<C-c><C-k>",
          },
        },
      })

      -- Heading colors matching kanagawa dragon (same as Doom config)
      vim.api.nvim_set_hl(0, "@org.headline.level1", { fg = "#c4746e", bold = true })
      vim.api.nvim_set_hl(0, "@org.headline.level2", { fg = "#8ba4b0", bold = true })
      vim.api.nvim_set_hl(0, "@org.headline.level3", { fg = "#8ea4a2", bold = true })
      vim.api.nvim_set_hl(0, "@org.headline.level4", { fg = "#a292a3", bold = true })
      vim.api.nvim_set_hl(0, "@org.headline.level5", { fg = "#c4b28a" })
      vim.api.nvim_set_hl(0, "@org.headline.level6", { fg = "#87a987" })
      vim.api.nvim_set_hl(0, "@org.headline.level7", { fg = "#8ba4b0" })
      vim.api.nvim_set_hl(0, "@org.headline.level8", { fg = "#938aa9" })

      -- Emphasis faces
      vim.api.nvim_set_hl(0, "@org.bold", { fg = "#c4746e", bold = true })
      vim.api.nvim_set_hl(0, "@org.italic", { fg = "#8ba4b0", italic = true })
      vim.api.nvim_set_hl(0, "@org.underline", { fg = "#8ea4a2", underline = true })
      vim.api.nvim_set_hl(0, "@org.code", { fg = "#c4b28a", bg = "#1a1a1a" })
      vim.api.nvim_set_hl(0, "@org.verbatim", { fg = "#87a987", bg = "#1a1a1a" })
      vim.api.nvim_set_hl(0, "@org.strikethrough", { fg = "#625e5a", strikethrough = true })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "org",
        callback = function()
          vim.opt_local.conceallevel = 2
          vim.opt_local.concealcursor = "nc"
          vim.keymap.set("n", "cit", function()
            require("orgmode").action("org_mappings.todo_next_state")
          end, { buffer = true, desc = "Cycle TODO state" })
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
          headlines = { "◉", "○", "●", "○", "●" },
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

      vim.keymap.set("n", "<leader>ra", function() require("orgmode").action("agenda.prompt") end, { desc = "Org agenda" })
      vim.keymap.set("n", "<leader>rf", function() roam.api.find_node() end, { desc = "Find node" })
      vim.keymap.set("n", "<leader>ri", function() roam.api.insert_node() end, { desc = "Insert node link" })
      vim.keymap.set("n", "<leader>rb", function() roam.ui.toggle_node_buffer() end, { desc = "Toggle backlinks" })
      vim.keymap.set("n", "<leader>rd", function() org_roam.open_today_daily_note() end, { desc = "Open today's note" })

      vim.api.nvim_create_autocmd("BufWritePost", {
        group = vim.api.nvim_create_augroup("trip_org_roam_sync", { clear = true }),
        pattern = "*.org",
        callback = function()
          local path = vim.fn.expand("%:p")

          local ok, roam = pcall(require, "org-roam")
          if ok then
            pcall(function()
              roam.database:load_file({ path = path, force = true }):wait()
            end)
          end

          vim.fn.jobstart({
            "emacsclient", "--no-wait", "--eval",
            string.format('(progn (org-roam-db-update-file "%s") (org-roam-ui--send-graphdata))', path),
          }, { detach = true })
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

      vim.keymap.set("n", "<leader>rs", function() ext.search_headings() end, { desc = "Search headings" })
      vim.keymap.set("n", "<leader>rr", function() ext.refile_heading() end, { desc = "Refile heading" })
      vim.keymap.set("n", "<leader>rl", function() ext.insert_link() end, { desc = "Insert link" })
      vim.keymap.set("n", "<leader>rt", function() ext.search_tags() end, { desc = "Search by tag" })
    end,
  },
}
