-- ascii-splash: replace Neovim's empty start buffer with a random ascii.nvim logo.
local M = {}

local config = { category = "text", subcategory = "neovim" }

local function art_size(lines)
  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  return width, #lines
end

local function fits(lines, win)
  local width, height = art_size(lines)
  return width <= vim.api.nvim_win_get_width(win) and height <= vim.api.nvim_win_get_height(win)
end

-- Random piece that fits the window, or nil when none does.
local function pick(win)
  local pieces = require("ascii").art[config.category][config.subcategory] or {}
  local candidates = {}
  for _, lines in pairs(pieces) do
    if fits(lines, win) then
      table.insert(candidates, lines)
    end
  end
  return candidates[math.random(#candidates)]
end

local function render(buf, win, lines)
  local width, height = art_size(lines)
  local left = string.rep(" ", math.floor((vim.api.nvim_win_get_width(win) - width) / 2))
  local out = {}
  for _ = 1, math.floor((vim.api.nvim_win_get_height(win) - height) / 2) do
    table.insert(out, "")
  end
  local top = #out
  for _, line in ipairs(lines) do
    table.insert(out, left .. line)
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false

  local ns = vim.api.nvim_create_namespace("ascii-splash")
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for row = top, #out - 1 do
    vim.api.nvim_buf_set_extmark(buf, ns, row, 0, { end_row = row, end_col = #out[row + 1], hl_group = "AsciiSplash" })
  end
  vim.api.nvim_win_set_cursor(win, { 1, 0 })
end

-- Only the untouched start buffer: no file arguments, no stdin, nothing typed.
local function is_start_buffer(buf)
  return vim.fn.argc() == 0
    and not vim.g.ascii_splash_stdin
    and vim.api.nvim_buf_get_name(buf) == ""
    and vim.api.nvim_buf_line_count(buf) == 1
    and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ""
    and not vim.bo[buf].modified
end

function M.show()
  local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  if not is_start_buffer(buf) then
    return
  end
  local lines = pick(win)
  if not lines then
    return
  end

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "ascii-splash"
  local wo = vim.wo[win][0]
  wo.number, wo.relativenumber, wo.cursorline, wo.list = false, false, false, false
  wo.signcolumn, wo.colorcolumn, wo.statuscolumn, wo.fillchars = "no", "", "", "eob: "
  render(buf, win, lines)

  -- Start typing like on a normal empty buffer; `q` quits.
  for _, key in ipairs({ "i", "a", "o" }) do
    vim.keymap.set("n", key, "<cmd>enew | startinsert<CR>", { buffer = buf, desc = "New buffer" })
  end
  vim.keymap.set("n", "q", "<cmd>quit<CR>", { buffer = buf, desc = "Quit" })

  local group = vim.api.nvim_create_augroup("ascii-splash", { clear = true })
  vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = function()
      local shown = vim.fn.bufwinid(buf)
      if shown == -1 then
        return
      end
      if not fits(lines, shown) then
        lines = pick(shown) or lines
      end
      render(buf, shown, lines)
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    buffer = buf,
    callback = function() vim.api.nvim_del_augroup_by_id(group) end,
  })
end

function M.setup(opts)
  config = vim.tbl_extend("force", config, opts or {})
  math.randomseed(vim.uv.hrtime())
  vim.api.nvim_set_hl(0, "AsciiSplash", { default = true, link = "Function" })
  vim.opt.shortmess:append("I")

  local group = vim.api.nvim_create_augroup("ascii-splash-start", { clear = true })
  vim.api.nvim_create_autocmd("StdinReadPre", {
    group = group,
    callback = function() vim.g.ascii_splash_stdin = true end,
  })
  vim.api.nvim_create_autocmd("VimEnter", { group = group, once = true, callback = M.show })
end

return M
