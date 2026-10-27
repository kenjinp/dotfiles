-- omp (Oh My Pi) integration: prompt modal -> one-shot or interactive run in a terminal split.
local M = {}

local function project_root()
  local name = vim.api.nvim_buf_get_name(0)
  local root = name ~= "" and vim.fs.root(name, { ".git" }) or nil
  return root or vim.uv.cwd() or "."
end

-- Snapshot disk content of every loaded named buffer, so we can tell after the
-- run which files omp actually changed (exact content compare, not mtime).
local function snapshot()
  local snap = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if name ~= "" and vim.api.nvim_buf_is_loaded(buf) and vim.fn.filereadable(name) == 1 then
      snap[buf] = vim.fn.readfile(name)
    end
  end
  return snap
end

local function disk_changed(buf, snap)
  local name = vim.api.nvim_buf_get_name(buf)
  if not snap[buf] or vim.fn.filereadable(name) ~= 1 then return false end
  return not vim.deep_equal(vim.fn.readfile(name), snap[buf])
end

local function reload_buf(buf, force)
  vim.api.nvim_buf_call(buf, function()
    -- pcall: a swapfile ATTENTION prompt or other transient failure must not
    -- abort the remaining reloads.
    pcall(vim.cmd, force and "edit!" or "edit")
  end)
end

-- After omp finishes: reload every buffer whose file changed on disk.
-- Unsaved edits are never silently discarded -- they get a confirmation.
local function reload_changed(snap)
  local conflicts = {}
  for buf in pairs(snap) do
    if vim.api.nvim_buf_is_valid(buf) and disk_changed(buf, snap) then
      if vim.bo[buf].modified then
        table.insert(conflicts, buf)
      else
        reload_buf(buf, false)
      end
    end
  end
  for _, buf in ipairs(conflicts) do
    local short = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
    vim.ui.select({
      "Reload from disk (discard my unsaved edits)",
      "Keep my edits (omp's version stays on disk until you decide)",
    }, {
      prompt = ("omp changed %s on disk, but you have unsaved edits in it."):format(short),
    }, function(choice)
      if choice == 1 then reload_buf(buf, true) end
    end)
  end
end

local function open_term(cmd, on_exit)
  vim.cmd("botright 15split")
  vim.cmd("terminal " .. cmd)
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].bufhidden = "wipe"
  vim.b[buf].omp_term = true
  vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, desc = "Close omp output" })
  vim.cmd("wincmd p") -- keep focus in the file; output stays visible in the split
  if on_exit then
    vim.api.nvim_create_autocmd("TermClose", {
      buffer = buf,
      callback = function()
        -- Defer out of the TermClose autocmd: reloads can trigger prompts
        -- (swapfile, confirmation dialogs) that must not run nested.
        vim.schedule(on_exit)
        return true -- one-shot autocmd
      end,
    })
  end
end

--- One-shot: prompt modal, run omp -p against the current file (passed as @file context).
function M.ask_file()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then
    return M.ask_dir()
  end
  vim.ui.input({ prompt = "omp (file) ❯ " }, function(input)
    if not input or input == "" then return end
    local cwd = vim.fn.shellescape(vim.fs.dirname(name))
    local file = vim.fn.shellescape("@" .. name)
    local ask = vim.fn.shellescape(input)
    local snap = snapshot()
    open_term("omp -p --cwd " .. cwd .. " " .. file .. " " .. ask,
      function() reload_changed(snap) end)
  end)
end

--- One-shot: prompt modal, run omp -p in the project root (git root or cwd).
function M.ask_dir()
  vim.ui.input({ prompt = "omp (dir) ❯ " }, function(input)
    if not input or input == "" then return end
    local cmd = "omp -p --cwd " .. vim.fn.shellescape(project_root()) .. " "
      .. vim.fn.shellescape(input)
    local snap = snapshot()
    open_term(cmd, function() reload_changed(snap) end)
  end)
end

--- Interactive omp session in a terminal split, rooted at the project root.
function M.interactive()
  open_term("omp --cwd " .. vim.fn.shellescape(project_root()))
end

return M
