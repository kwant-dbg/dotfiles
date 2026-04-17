local M = {}

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

function M.daily_note_title(date)
  return os.date("%A, %B %d, %Y", date_to_timestamp(date))
end

function M.daily_note_path(date)
  return vim.fn.expand("~/notes/roam/daily/" .. (date or M.today_date()) .. ".org")
end

function M.daily_note_templates(date)
  date = date or M.today_date()

  return {
    d = {
      description = "default",
      target = "daily/" .. date .. ".org",
      header = table.concat({
        "#+title: ${title}",
        "#+filetags: :daily:",
        "#+date: " .. date,
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

function M.open_today_daily_note()
  local path = M.ensure_daily_note()
  vim.cmd.edit(vim.fn.fnameescape(path))
end

return M
