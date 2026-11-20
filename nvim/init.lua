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

-- 3. Check system dependencies for a fresh machine setup
-- Tree-sitter needs 'gcc' to compile syntax parsers
if vim.fn.executable("gcc") == 0 then
  vim.schedule(function()
    vim.notify(
      "gcc not found: run 'sudo apt install build-essential' in your terminal for Tree-sitter.",
      vim.log.levels.WARN
    )
  end)
end

-- Mason needs 'npm' and 'unzip' to download and install pyright automatically
if vim.fn.executable("node") == 0 or vim.fn.executable("npm") == 0 or vim.fn.executable("unzip") == 0 then
  vim.schedule(function()
    vim.notify(
      "npm/unzip not found: run 'sudo apt install nodejs npm unzip' in your terminal for Mason/pyright.",
      vim.log.levels.WARN
    )
  end)
end

-- 4. Initialize lazy.nvim and declare plugins
require("lazy").setup({
  spec = {
    {
      "nvim-treesitter/nvim-treesitter",
      branch = "master",
      build = ":TSUpdate",
      config = function()
        require("nvim-treesitter.configs").setup({
          ensure_installed = { "lua", "python", "vim", "vimdoc", "query" },
          highlight = { enable = true },
          indent = { enable = true }, -- Enables Tree-sitter indentation rules
        })
      end,
    },
    {
      "folke/tokyonight.nvim",
      lazy = false,    -- Load immediately at startup so the UI doesn't flash default colors
      priority = 1000, -- Load before all other plugins so they inherit this theme's colors
      config = function()
        vim.cmd.colorscheme("tokyonight-night")
      end,
    },
    {
      "windwp/nvim-autopairs",
      event = "InsertEnter", -- Loads automatically the first time you enter Insert mode
      config = function()
        require("nvim-autopairs").setup({
          check_ts = true, -- Uses your nvim-treesitter parsers for smarter pairing
        })
      end,
    },
    {
      -- Python Language Server (LSP) setup for code navigation (gd) and docs (K)
      "neovim/nvim-lspconfig",
      dependencies = {
        "williamboman/mason.nvim",           -- Tool installer ("App Store" for LSPs)
        "williamboman/mason-lspconfig.nvim", -- Bridges Mason and lspconfig
      },
      config = function()
        -- Step A: Initialize Mason and auto-install pyright in ~/.local/share/nvim/mason
        require("mason").setup()
        require("mason-lspconfig").setup({
          ensure_installed = { "pyright" },
        })

        -- Step B: Create shortcuts ONLY when an LSP attaches to the current file
        -- Tip: After jumping with 'gd', press 'Ctrl + o' to jump back to where you were!
        vim.api.nvim_create_autocmd("LspAttach", {
          callback = function(event)
            local opts = { buffer = event.buf }
            -- Jump to where a class/function is defined (even inside .venv!)
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
            -- Show popup documentation for the word under the cursor
            vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
            -- Show error details if a line has a warning/error
            vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
          end,
        })

        -- Step C: Start pyright (compatible with both Neovim 0.11+ and older versions)
        if vim.fn.has("nvim-0.11") == 1 then
          vim.lsp.enable("pyright")
        else
          require("lspconfig").pyright.setup({})
        end
      end,
    },
		
{
  "folke/persistence.nvim",
  event = "BufReadPre",
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

-- =========================================================================
-- Personal settings, keymaps, and <leader>r Python runner
-- =========================================================================

-- Normal mode: Paste after cursor
vim.keymap.set("n", "<leader>p", '"+p', { desc = "Paste from system clipboard" })

-- Visual mode: Paste over highlighted text
vim.keymap.set("v", "<leader>p", '"+p', { desc = "Paste from system clipboard" })

-- Insert mode: Paste over highlighted text
--vim.keymap.set("i", "<leader>p", '<C-r>+', { desc = "Paste from system clipboard" })

vim.keymap.set("i", "jk", "<C-c>", { desc = "Escape" })

vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Written" })
vim.keymap.set("n", "<leader>z", ":e!<CR>", { desc = "Restore" })

-- Display line number
vim.opt.number = true
-- Enable automatic syntax-aware folding via Tree-sitter
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99 -- Open files fully expanded; use zc/zM to fold on demand
-- Share the Windows clipboard
vim.opt.clipboard = "unnamedplus"

local run_buf = nil
vim.keymap.set("n", "<leader>r", function()
  vim.cmd("update")
  if run_buf and vim.api.nvim_buf_is_valid(run_buf) then
    vim.api.nvim_buf_delete(run_buf, { force = true })
  end

  local file = vim.fn.expand("%:p")

  -- 1. Create the buffer and bind 'q' BEFORE starting Python
  run_buf = vim.api.nvim_create_buf(false, true)
  vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = run_buf, silent = true })

  -- 2. Open the bottom split and display the buffer
  vim.cmd("botright 12split")
  vim.api.nvim_win_set_buf(0, run_buf)

-- 3. Auto-detect .venv or venv upward from the file's directory; fallback to python3
  local file_dir = vim.fn.expand("%:p:h")
  local venv_py = vim.fs.find({ ".venv/bin/python3", "venv/bin/python3" }, {
    upward = true,
    path = file_dir,
  })[1]

  local py_exec = venv_py or "python3"
  local cmd = { py_exec, file }
  if vim.fn.has("nvim-0.11") == 1 then
    vim.fn.jobstart(cmd, { term = true })
  else
    vim.fn.termopen(cmd)
  end
end, { desc = "Run Python file in a fresh split" })


-- Auto-save persistence session on every file write (survives terminal force-close)
vim.api.nvim_create_autocmd("BufWritePost", {
  callback = function()
    if package.loaded["persistence"] then
      require("persistence").save()
    end
  end,
})
