local M = {}
local ROAM_DIR = vim.fs.normalize(vim.fn.expand("~/notes/roam"))
local DAILY_DIR = ROAM_DIR .. "/daily"
local INBOX_FILE = ROAM_DIR .. "/inbox.org"

local function random_uuid()
  return require("org-roam.core.utils.random").uuid_v4()
end

local function date_to_timestamp(date)
  if not date then
    return os.time()
  end

  local year, month, day = date:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
  if not year then
    return os.time()
  end

  return os.time({
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
    hour = 12,
  })
end

function M.today_date()
  return os.date("%Y-%m-%d")
end

function M.roam_dir()
  return ROAM_DIR
end

function M.daily_dir()
  return DAILY_DIR
end

function M.default_notes_file()
  return INBOX_FILE
end

function M.agenda_files()
  return { ROAM_DIR .. "/**/*.org" }
end

function M.daily_note_title(date)
  return os.date("%A, %B %d, %Y", date_to_timestamp(date))
end

function M.daily_note_path(date)
  return DAILY_DIR .. "/" .. (date or M.today_date()) .. ".org"
end

function M.daily_note_templates(date)
  date = date or M.today_date()

  return {
    d = {
      description = "default",
      target = "daily/" .. date .. ".org",
      header = table.concat({
        "#+TITLE: ${title}",
        "#+FILETAGS: :daily:",
        "#+DATE: " .. date,
        "",
      }, "\n"),
      template = table.concat({
        "* Tasks",
        "",
        "** TODO %?",
        "",
        "* Thoughts",
        "",
        "",
        "* Connections",
        "",
        "",
        "* Reflection",
      }, "\n"),
    },
  }
end

function M.ensure_daily_note(date)
  date = date or M.today_date()
  local path = M.daily_note_path(date)

  if vim.fn.filereadable(path) == 1 then
    return path
  end

  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")

  local template = M.daily_note_templates(date).d
  local header = template.header:gsub("${title}", M.daily_note_title(date), 1)
  local lines = {
    ":PROPERTIES:",
    ":ID:       " .. random_uuid(),
    ":END:",
  }

  vim.list_extend(lines, vim.split(header, "\n", { plain = true, trimempty = false }))
  vim.list_extend(lines, vim.split(template.template, "\n", { plain = true, trimempty = false }))
  vim.fn.writefile(lines, path)

  local ok, roam = pcall(require, "org-roam")
  if ok then
    pcall(function()
      roam.database:load_file({ path = path, force = true }):wait()
    end)
  end

  return path
end

function M.is_roam_file(path)
  local normalized = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
  return normalized == ROAM_DIR or normalized:sub(1, #ROAM_DIR + 1) == ROAM_DIR .. "/"
end

function M.should_sync_with_emacs()
  local enabled = vim.g.org_roam_sync_with_emacs
  if enabled == nil then
    enabled = true
  end

  return enabled == true and vim.fn.executable("emacsclient") == 1
end

function M.sync_with_emacs(path)
  if not M.should_sync_with_emacs() or not M.is_roam_file(path) then
    return
  end

  vim.fn.jobstart({
    "emacsclient",
    "--no-wait",
    "--eval",
    string.format('(progn (org-roam-db-update-file "%s") (ignore-errors (org-roam-ui--send-graphdata)))', path),
  }, { detach = true })
end

function M.open_today_daily_note()
  local path = M.ensure_daily_note()
  vim.cmd.edit(vim.fn.fnameescape(path))
end

return M
