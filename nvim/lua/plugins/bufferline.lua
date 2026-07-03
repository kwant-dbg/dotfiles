return {
  {
    "akinsho/bufferline.nvim",
    opts = function(_, opts)
      local palette = require("config.palette")

      opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
        mode = "buffers",
        numbers = function(opts)
          return string.format("%s", opts.ordinal)
        end,
        close_command = "bdelete! %d",
        right_mouse_command = "bdelete! %d",
        middle_mouse_command = nil,
        indicator = {
          style = "none",
        },
        buffer_close_icon = "󰅖",
        modified_icon = "●",
        close_icon = "",
        left_trunc_marker = "",
        right_trunc_marker = "",
        max_name_length = 22,
        max_prefix_length = 14,
        tab_size = 18,
        diagnostics = "nvim_lsp",
        diagnostics_update_in_insert = false,
        diagnostics_indicator = function(_, _, diagnostics_dict)
          local parts = {}
          if diagnostics_dict.error then
            parts[#parts + 1] = "E" .. diagnostics_dict.error
          end
          if diagnostics_dict.warning then
            parts[#parts + 1] = "W" .. diagnostics_dict.warning
          end
          if diagnostics_dict.info then
            parts[#parts + 1] = "I" .. diagnostics_dict.info
          end
          if diagnostics_dict.hint then
            parts[#parts + 1] = "H" .. diagnostics_dict.hint
          end
          return #parts > 0 and " " .. table.concat(parts, " ") or ""
        end,
        offsets = {
          {
            filetype = "neo-tree",
            text = "Files",
            text_align = "left",
            separator = true,
          },
        },
        color_icons = true,
        show_buffer_icons = true,
        show_buffer_close_icons = false,
        show_close_icon = false,
        show_tab_indicators = true,
        persist_buffer_sort = true,
        separator_style = { "", "" },
        enforce_regular_tabs = false,
        always_show_bufferline = false,
        hover = {
          enabled = true,
          delay = 160,
          reveal = { "close" },
        },
        sort_by = "insert_after_current",
      })

      opts.highlights = vim.tbl_deep_extend("force", opts.highlights or {}, {
        fill = { bg = palette.bg },
        background = { fg = palette.muted, bg = palette.bg_tab, italic = false },
        buffer_visible = { fg = palette.fg, bg = palette.bg_tab, italic = false },
        buffer_selected = { fg = palette.purple_muted, bg = palette.bg_alt, bold = true, italic = false },
        numbers = { fg = palette.muted, bg = palette.bg_tab, italic = false },
        numbers_visible = { fg = palette.muted, bg = palette.bg_tab, italic = false },
        numbers_selected = { fg = palette.purple_muted, bg = palette.bg_alt, bold = true, italic = false },
        diagnostic = { fg = palette.muted, bg = palette.bg_tab, italic = false },
        diagnostic_visible = { fg = palette.muted, bg = palette.bg_tab, italic = false },
        diagnostic_selected = { fg = palette.orange_soft, bg = palette.bg_alt, bold = true, italic = false },
        hint = { fg = palette.muted, bg = palette.bg_tab, italic = false },
        hint_visible = { fg = palette.muted, bg = palette.bg_tab, italic = false },
        hint_selected = { fg = palette.green_soft, bg = palette.bg_alt, bold = true, italic = false },
        hint_diagnostic = { fg = palette.muted, bg = palette.bg_tab, italic = false },
        hint_diagnostic_visible = { fg = palette.muted, bg = palette.bg_tab, italic = false },
        hint_diagnostic_selected = { fg = palette.green_soft, bg = palette.bg_alt, bold = true, italic = false },
        info = { fg = palette.muted, bg = palette.bg_tab, italic = false },
        info_visible = { fg = palette.muted, bg = palette.bg_tab, italic = false },
        info_selected = { fg = palette.purple_muted, bg = palette.bg_alt, bold = true, italic = false },
        info_diagnostic = { fg = palette.muted, bg = palette.bg_tab, italic = false },
        info_diagnostic_visible = { fg = palette.muted, bg = palette.bg_tab, italic = false },
        info_diagnostic_selected = { fg = palette.purple_muted, bg = palette.bg_alt, bold = true, italic = false },
        warning = { fg = palette.orange_soft, bg = palette.bg_tab, italic = false },
        warning_visible = { fg = palette.orange_soft, bg = palette.bg_tab, italic = false },
        warning_selected = { fg = palette.orange_soft, bg = palette.bg_alt, bold = true, italic = false },
        warning_diagnostic = { fg = palette.orange_soft, bg = palette.bg_tab, italic = false },
        warning_diagnostic_visible = { fg = palette.orange_soft, bg = palette.bg_tab, italic = false },
        warning_diagnostic_selected = { fg = palette.orange_soft, bg = palette.bg_alt, bold = true, italic = false },
        error = { fg = palette.red_soft, bg = palette.bg_tab, italic = false },
        error_visible = { fg = palette.red_soft, bg = palette.bg_tab, italic = false },
        error_selected = { fg = palette.red_soft, bg = palette.bg_alt, bold = true, italic = false },
        error_diagnostic = { fg = palette.red_soft, bg = palette.bg_tab, italic = false },
        error_diagnostic_visible = { fg = palette.red_soft, bg = palette.bg_tab, italic = false },
        error_diagnostic_selected = { fg = palette.red_soft, bg = palette.bg_alt, bold = true, italic = false },
        modified = { fg = palette.orange_soft, bg = palette.bg_tab, italic = false },
        modified_visible = { fg = palette.orange_soft, bg = palette.bg_tab, italic = false },
        modified_selected = { fg = palette.green_soft, bg = palette.bg_alt, bold = true, italic = false },
        duplicate = { fg = palette.muted, bg = palette.bg_tab, italic = false },
        duplicate_selected = { fg = palette.muted, bg = palette.bg_alt, bold = true, italic = false },
        separator = { fg = palette.bg_tab, bg = palette.bg_tab, underline = false },
        separator_visible = { fg = palette.bg_tab, bg = palette.bg_tab, underline = false },
        separator_selected = { fg = palette.bg_alt, bg = palette.bg_alt, underline = false },
        indicator_selected = { fg = palette.pink_soft, bg = palette.bg_alt, bold = true, italic = false, underline = false },
        tab = { fg = palette.muted, bg = palette.bg_tab, italic = false },
        tab_selected = { fg = palette.purple_muted, bg = palette.bg_alt, bold = true, italic = false },
        tab_separator = { fg = palette.bg_tab, bg = palette.bg_tab, underline = false },
        tab_separator_selected = { fg = palette.bg_alt, bg = palette.bg_alt, underline = false },
        close_button = { fg = palette.muted, bg = palette.bg_tab, italic = false },
        close_button_visible = { fg = palette.muted, bg = palette.bg_tab, italic = false },
        close_button_selected = { fg = palette.pink_soft, bg = palette.bg_alt, bold = true, italic = false },
        trunc_marker = { fg = palette.purple_muted, bg = palette.bg },
        offset_separator = { fg = palette.bg_alt, bg = palette.bg },
      })

      return opts
    end,
  },
}
