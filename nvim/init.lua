-- Prerequisites (Ubuntu / WSL2):
--   sudo apt update && sudo apt install -y build-essential unzip curl nodejs npm ripgrep
--   mkdir -p ~/.config && ln -sfn ~/.dotfiles/nvim ~/.config/nvim

-- 1. Set leader keys BEFORE loading lazy.nvim so plugin keymaps bind properly
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- 2. Bootstrap lazy.nvim (clones from GitHub automatically if missing)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    lazyrepo,
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Helper: reusable C compiler check for both Tree-sitter and startup diagnostics
local function has_c_compiler()
  return vim.fn.executable("gcc") == 1
    or vim.fn.executable("clang") == 1
    or vim.fn.executable("cc") == 1
end

-- 3. Initialize lazy.nvim and declare plugins
require("lazy").setup({
  spec = {
    {
      "folke/snacks.nvim",
      priority = 1000,
      lazy = false,
      opts = {
        notifier = { enabled = true, timeout = 5000 },
      },
      keys = {
        { "<leader>un", function() Snacks.notifier.show_history() end, desc = "Notification History" },
      },
    },
    {
      "nvim-treesitter/nvim-treesitter",
      branch = "master",
      build = ":TSUpdate",
      config = function()
        require("nvim-treesitter.configs").setup({
          ensure_installed = has_c_compiler() and { "lua", "python", "vim", "vimdoc", "query" } or {},
          highlight = { enable = true },
          indent = { enable = true },
        })
      end,
    },
    {
      "folke/tokyonight.nvim",
      lazy = false,
      priority = 1000,
      config = function()
        vim.cmd.colorscheme("tokyonight-night")
      end,
    },
    {
      "windwp/nvim-autopairs",
      event = "InsertEnter",
      config = function()
        require("nvim-autopairs").setup({
          check_ts = true,
        })
      end,
    },
    {
      "neovim/nvim-lspconfig",
      dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
      },
      config = function()
        require("mason").setup()
        local has_node_npm = vim.fn.executable("node") == 1 and vim.fn.executable("npm") == 1
        require("mason-lspconfig").setup({
          ensure_installed = has_node_npm and { "pyright" } or {},
        })

        vim.api.nvim_create_autocmd("LspAttach", {
          callback = function(event)
            local opts = { buffer = event.buf }
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
            vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
            vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
          end,
        })

        if vim.fn.has("nvim-0.11") == 1 then
          vim.lsp.enable("pyright")
        else
          require("lspconfig").pyright.setup({})
        end
      end,
    },
    {
      "folke/persistence.nvim",
      event = { "BufReadPre", "SessionLoadPost" },
      opts = {},
      keys = {
        { "<leader>qs", function() require("persistence").load() end, desc = "Restore Current Dir Session" },
        { "<leader>qS", function() require("persistence").select() end, desc = "Select Any Saved Session" },
        { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
      },
    },
  },
  checker = { enabled = false },
})

-- 4. Check system dependencies for a fresh machine setup
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local missing_pkgs = {}
    local details = {}

    if not has_c_compiler() then
      table.insert(missing_pkgs, "build-essential")
      table.insert(details, "- gcc (required by nvim-treesitter to compile parsers)")
    end
    if vim.fn.executable("node") == 0 or vim.fn.executable("npm") == 0 then
      table.insert(missing_pkgs, "nodejs npm")
      table.insert(details, "- node/npm (required by Mason to install pyright)")
    end
    if vim.fn.executable("unzip") == 0 then
      table.insert(missing_pkgs, "unzip")
      table.insert(details, "- unzip (required by Mason to extract packages)")
    end

    if #missing_pkgs > 0 then
      local msg = table.concat({
        "Missing system tools:",
        table.concat(details, "\n"),
        "",
        "Run in terminal:",
        "sudo apt update && sudo apt install -y " .. table.concat(missing_pkgs, " "),
      }, "\n")

      vim.notify(msg, vim.log.levels.ERROR, {
        title = "System Dependency Check",
        timeout = 15000,
      })
    end
  end,
})

-- =========================================================================
-- 5. Personal settings, keymaps, and <leader>r Python runner
-- =========================================================================

vim.opt.number = true

-- Strip Windows carriage returns (\r / ^M) when pasting from Windows clipboard in WSL2
if vim.fn.has("wsl") == 1 then
  vim.g.clipboard = {
    name = "WslClipboard",
    copy = {
      ["+"] = { "clip.exe" },
      ["*"] = { "clip.exe" },
    },
    paste = {
      ["+"] = { "powershell.exe", "-NoLogo", "-NoProfile", "-Command", "[Console]::Out.Write(((Get-Clipboard -Raw) -replace [char]13, ''))" },
      ["*"] = { "powershell.exe", "-NoLogo", "-NoProfile", "-Command", "[Console]::Out.Write(((Get-Clipboard -Raw) -replace [char]13, ''))" },
    },
    cache_enabled = 0,
  }
end

vim.opt.clipboard = "unnamedplus"
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99
vim.opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" }

-- Keymaps
vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit Insert mode" })
vim.keymap.set("n", "<leader>p", '"+p', { desc = "Paste from system clipboard" })
vim.keymap.set("v", "<leader>p", '"+P', { desc = "Paste without overwriting clipboard" })
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
vim.keymap.set("n", "<leader>z", "<cmd>e!<CR>", { desc = "Reload file from disk" })

-- Python runner (<leader>r)
local run_buf = nil
vim.keymap.set("n", "<leader>r", function()
  local file = vim.fn.expand("%:p")
  if file == "" then
    vim.notify("Save the file first before running.", vim.log.levels.WARN)
    return
  end

  vim.cmd("update")
  if run_buf and vim.api.nvim_buf_is_valid(run_buf) then
    vim.api.nvim_buf_delete(run_buf, { force = true })
  end

  run_buf = vim.api.nvim_create_buf(false, true)
  vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = run_buf, silent = true })

  vim.cmd("botright 12split")
  vim.api.nvim_win_set_buf(0, run_buf)

  local file_dir = vim.fn.expand("%:p:h")
  local venv_py = vim.fs.find({ ".venv/bin/python3", "venv/bin/python3" }, {
    upward = true,
    path = file_dir,
  })[1]

  local cmd = { venv_py or "python3", file }
  if vim.fn.has("nvim-0.11") == 1 then
    vim.fn.jobstart(cmd, { term = true })
  else
    vim.fn.termopen(cmd)
  end
  vim.bo[run_buf].buflisted = false
end, { desc = "Run Python file in a fresh split" })

-- Auto-save persistence session on every file write (survives terminal force-close)
vim.api.nvim_create_autocmd("BufWritePost", {
  callback = function()
    if package.loaded["persistence"] then
      require("persistence").save()
    end
  end,
})
