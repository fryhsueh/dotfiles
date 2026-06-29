print("advent of neovim")
print("the second line")
vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- Normal mode: Paste after cursor
vim.keymap.set("n", "<leader>p", '"+p', { desc = "Paste from system clipboard" })

-- Visual mode: Paste over highlighted text
vim.keymap.set("v", "<leader>p", '"+p', { desc = "Paste from system clipboard" })

-- Insert mode: Paste over highlighted text
vim.keymap.set("i", "<leader>p", '<C-r>+', { desc = "Paste from system clipboard" })

vim.keymap.set("i", "jk", "<C-c>", { desc = "Escape"})

vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Written"})
-- Display line number
vim.opt.number = true
-- Share the Windows clipboard
vim.opt.clipboard = "unnamedplus"

-- Better window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Jump to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Jump to lower window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Jump to upper window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Jump to right window" })

-- Terminal mode window navigation
vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "Jump to left window from terminal" })
vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "Jump to lower window from terminal" })
vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "Jump to upper window from terminal" })
vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "Jump to right window from terminal" })

-- Press Esc twice to exit Terminal Mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
