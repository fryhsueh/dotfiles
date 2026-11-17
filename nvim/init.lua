vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- Normal mode: Paste after cursor
vim.keymap.set("n", "<leader>p", '"+p', { desc = "Paste from system clipboard" })

-- Visual mode: Paste over highlighted text
vim.keymap.set("v", "<leader>p", '"+p', { desc = "Paste from system clipboard" })

-- Insert mode: Paste over highlighted text
--vim.keymap.set("i", "<leader>p", '<C-r>+', { desc = "Paste from system clipboard" })

vim.keymap.set("i", "jk", "<C-c>", { desc = "Escape"})

vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Written"})
vim.keymap.set("n", "<leader>z", ":e!<CR>", { desc = "Restore"})

-- Display line number
vim.opt.number = true
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

  -- 3. Start Python directly inside this buffer
  local cmd = { "python3", file }
  if vim.fn.has("nvim-0.11") == 1 then
    vim.fn.jobstart(cmd, { term = true })
  else
    vim.fn.termopen(cmd)
  end

end, { desc = "Run Python file in a fresh split" })
