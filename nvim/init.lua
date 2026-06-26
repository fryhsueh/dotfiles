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
