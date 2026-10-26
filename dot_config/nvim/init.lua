-- ~/.config/nvim/init.lua  (Neovim 0.11+) - managed by chezmoi.
-- Leader is <Space>. Press <Space> and wait to see every mapping (which-key).

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Per-machine settings rendered by chezmoi into lua/machine.lua (`chezmoi init` asks).
local has_machine, machine = pcall(require, "machine")
vim.g.have_nerd_font = has_machine and machine.nerd_font or false

-- ── Options ────────────────────────────────────────────────────────────────
local o = vim.opt
o.number = true
o.relativenumber = true
o.mouse = "a"
o.showmode = false
o.breakindent = true
o.undofile = true
o.ignorecase = true
o.smartcase = true
o.signcolumn = "yes"
o.updatetime = 250
o.timeoutlen = 300
o.splitright = true
o.splitbelow = true
o.list = true
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
o.inccommand = "split"
o.cursorline = true
o.scrolloff = 8
o.termguicolors = true
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.confirm = true
o.clipboard = "unnamedplus"

-- WSL: share the system clipboard with Windows.
if vim.fn.has("wsl") == 1 then
  vim.g.clipboard = {
    name = "WslClipboard",
    copy = { ["+"] = "clip.exe", ["*"] = "clip.exe" },
    paste = {
      ["+"] = 'powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
      ["*"] = 'powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    },
    cache_enabled = 0,
  }
end

-- ── Basic keymaps ──────────────────────────────────────────────────────────
local map = vim.keymap.set
map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Write file" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show line diagnostics" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

vim.diagnostic.config({
  severity_sort = true,
  float = { border = "rounded", source = "if_many" },
  virtual_text = { spacing = 2 },
})

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight on yank",
  callback = function() vim.hl.on_yank() end,
})

-- ── lazy.nvim bootstrap ────────────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    error("Error cloning lazy.nvim:\n" .. out)
  end
  -- Check out the lazy.nvim commit pinned in lazy-lock.json so new machines match it.
  local lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"
  local ok, lock = pcall(function() return vim.json.decode(table.concat(vim.fn.readfile(lockfile), "\n")) end)
  if ok and lock["lazy.nvim"] then
    vim.fn.system({ "git", "-C", lazypath, "checkout", "--quiet", lock["lazy.nvim"].commit })
  end
end
vim.opt.rtp:prepend(lazypath)

local js_fts = { "javascript", "javascriptreact", "typescript", "typescriptreact" }
local ts_parsers = {
  "javascript", "typescript", "tsx", "json", "html", "css", "lua", "luadoc",
  "vim", "vimdoc", "query", "markdown", "markdown_inline", "bash", "regex",
}

require("lazy").setup({
  -- Colorscheme
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    config = function() vim.cmd.colorscheme("tokyonight-night") end,
  },

  -- Seamless Ctrl-h/j/k/l between Neovim splits and tmux panes
  { "christoomey/vim-tmux-navigator" },

  -- Keymap hints
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      icons = { mappings = vim.g.have_nerd_font },
      spec = {
        { "<leader>f", group = "Find" },
        { "<leader>c", group = "Code" },
        { "<leader>g", group = "Git" },
      },
    },
  },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    event = "VimEnter",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-telescope/telescope-ui-select.nvim",
      { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          file_ignore_patterns = { "node_modules/", "%.git/", "dist/", "build/" },
        },
        pickers = {
          find_files = { hidden = true },
        },
        extensions = {
          ["ui-select"] = { require("telescope.themes").get_dropdown() },
        },
      })
      pcall(telescope.load_extension, "fzf")
      pcall(telescope.load_extension, "ui-select")

      local b = require("telescope.builtin")
      map("n", "<leader>ff", b.find_files, { desc = "Find files" })
      map("n", "<leader>fg", b.live_grep, { desc = "Grep project" })
      map("n", "<leader>fw", b.grep_string, { desc = "Grep word under cursor" })
      map("n", "<leader>fb", b.buffers, { desc = "Find buffers" })
      map("n", "<leader>fr", b.oldfiles, { desc = "Recent files" })
      map("n", "<leader>fh", b.help_tags, { desc = "Help" })
      map("n", "<leader>fk", b.keymaps, { desc = "Keymaps" })
      map("n", "<leader>fd", b.diagnostics, { desc = "Diagnostics" })
      map("n", "<leader>f.", b.resume, { desc = "Resume last search" })
      map("n", "<leader>gs", b.git_status, { desc = "Git status" })
      map("n", "<leader>/", b.current_buffer_fuzzy_find, { desc = "Search in buffer" })
      map("n", "<leader><leader>", b.buffers, { desc = "Buffers" })
    end,
  },

  -- Treesitter (syntax highlighting / indent). Neovim 0.12+ needs the `main`
  -- rewrite (`master` is frozen and unsupported there); `main` builds parsers
  -- with the tree-sitter CLI (`brew install tree-sitter-cli`). Older Neovim keeps
  -- `master`, which compiles parsers with gcc and needs no CLI (the CLI has no
  -- build for older glibc).
  vim.fn.has("nvim-0.12") == 1 and {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      ts.install(ts_parsers)

      local function start(buf, lang)
        if not vim.api.nvim_buf_is_valid(buf) or not pcall(vim.treesitter.start, buf, lang) then
          return
        end
        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
        callback = function(args)
          local buf, lang = args.buf, vim.treesitter.language.get_lang(args.match)
          if not lang then
            return
          end
          if vim.tbl_contains(ts.get_installed(), lang) then
            start(buf, lang)
          elseif vim.tbl_contains(ts.get_available(), lang) then -- auto_install
            ts.install(lang):await(vim.schedule_wrap(function(err)
              if not err then
                start(buf, lang)
              end
            end))
          end
        end,
      })
    end,
  } or {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = ts_parsers,
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
  },

  -- Auto-close / rename JSX & HTML tags
  { "windwp/nvim-ts-autotag", ft = { "html", "javascriptreact", "typescriptreact" }, opts = {} },

  -- Auto-pair brackets and quotes
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },

  -- LSP: Mason installs servers, mason-lspconfig enables them
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "mason-org/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local b = require("telescope.builtin")
          local function m(keys, fn, desc)
            map("n", keys, fn, { buffer = ev.buf, desc = desc })
          end
          m("gd", b.lsp_definitions, "Go to definition")
          m("gr", b.lsp_references, "References")
          m("gI", b.lsp_implementations, "Go to implementation")
          m("gy", b.lsp_type_definitions, "Go to type definition")
          m("gD", vim.lsp.buf.declaration, "Go to declaration")
          m("<leader>cs", b.lsp_document_symbols, "Document symbols")
          m("<leader>cS", b.lsp_dynamic_workspace_symbols, "Workspace symbols")
          m("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
          map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, { buffer = ev.buf, desc = "Code action" })
          -- K (hover), [d / ]d (diagnostics) and <C-s> (signature help, insert) are Neovim defaults.
        end,
      })

      vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })
      vim.lsp.config("lua_ls", {
        settings = { Lua = { diagnostics = { globals = { "vim" } } } },
      })

      require("mason-lspconfig").setup({
        ensure_installed = { "ts_ls", "eslint", "jsonls", "cssls", "html", "lua_ls" },
        automatic_enable = true,
      })
    end,
  },

  -- Completion
  {
    "saghen/blink.cmp",
    version = "1.*",
    opts = {
      keymap = { preset = "default" }, -- <C-y> accept, <C-space> open, <C-n>/<C-p> move
      appearance = { nerd_font_variant = "mono" },
      completion = { documentation = { auto_show = true, auto_show_delay_ms = 300 } },
      signature = { enabled = true },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      fuzzy = { implementation = "prefer_rust" }, -- falls back to Lua if the binary can't load
    },
  },

  -- Formatting: project Prettier on save for web files
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
      { "<leader>cf", function() require("conform").format({ async = true }) end, desc = "Format buffer" },
    },
    opts = {
      formatters_by_ft = (function()
        local t = {}
        for _, ft in ipairs(vim.list_extend(vim.deepcopy(js_fts), { "json", "css", "html", "markdown" })) do
          t[ft] = { "prettierd", "prettier", stop_after_first = true }
        end
        return t
      end)(),
      format_on_save = function(buf)
        if vim.g.disable_autoformat or vim.b[buf].disable_autoformat then return end
        return { timeout_ms = 1000, lsp_format = "never" }
      end,
      notify_no_formatters = false,
    },
    init = function()
      vim.api.nvim_create_user_command("FormatToggle", function()
        vim.g.disable_autoformat = not vim.g.disable_autoformat
        print("Format on save: " .. (vim.g.disable_autoformat and "off" or "on"))
      end, { desc = "Toggle format on save" })
    end,
  },

  -- Git signs in the gutter
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      on_attach = function(buf)
        local gs = require("gitsigns")
        map("n", "]h", function() gs.nav_hunk("next") end, { buffer = buf, desc = "Next hunk" })
        map("n", "[h", function() gs.nav_hunk("prev") end, { buffer = buf, desc = "Prev hunk" })
        map("n", "<leader>gp", gs.preview_hunk, { buffer = buf, desc = "Preview hunk" })
        map("n", "<leader>gr", gs.reset_hunk, { buffer = buf, desc = "Reset hunk" })
        map("n", "<leader>gb", gs.blame_line, { buffer = buf, desc = "Blame line" })
      end,
    },
  },

  -- File explorer as an editable buffer: `-` opens the parent directory
  {
    "stevearc/oil.nvim",
    lazy = false,
    opts = { view_options = { show_hidden = true }, columns = vim.g.have_nerd_font and { "icon" } or {} },
    keys = { { "-", "<cmd>Oil<CR>", desc = "Open parent directory" } },
  },

  -- File tree sidebar on the left. oil.nvim stays the directory handler (`-`, `nvim .`).
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font } },
    cmd = { "NvimTreeToggle", "NvimTreeFindFileToggle" },
    keys = { { "<leader>t", "<cmd>NvimTreeFindFileToggle<CR>", desc = "Toggle file tree" } },
    opts = {
      hijack_netrw = false,
      hijack_directories = { enable = false },
      view = { side = "left", width = 32 },
      filters = { dotfiles = false, custom = { "^.git$" } },
      renderer = {
        add_trailing = not vim.g.have_nerd_font,
        icons = {
          show = {
            file = vim.g.have_nerd_font,
            folder = vim.g.have_nerd_font,
            folder_arrow = vim.g.have_nerd_font,
            git = vim.g.have_nerd_font,
          },
        },
      },
    },
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        theme = "tokyonight",
        icons_enabled = vim.g.have_nerd_font,
        section_separators = "",
        component_separators = "|",
      },
    },
  },
}, {
  ui = { icons = vim.g.have_nerd_font and {} or {
    cmd = "⌘", config = "🛠", event = "📅", ft = "📂", init = "⚙", keys = "🗝", plugin = "🔌",
    runtime = "💻", require = "🌙", source = "📄", start = "🚀", task = "📌", lazy = "💤 ",
  } },
  checker = { enabled = false },
  change_detection = { notify = false },
})
