local builtin = require("telescope.builtin")

vim.g.mapleader = ","
vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
vim.keymap.set("n", "<leader>t", ":NvimTreeToggle<CR>", { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "<Esc>", ":noh<CR><Esc>", { noremap = true, silent = true })

local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Tabs
map('n', 't<Left>', '<Cmd>BufferPrevious<CR>', opts)
map('n', 't<right>', '<Cmd>BufferNext<CR>', opts)
map('n', 't1', '<Cmd>BufferGoto 1<CR>', opts)
map('n', 't2', '<Cmd>BufferGoto 2<CR>', opts)
map('n', 't3', '<Cmd>BufferGoto 3<CR>', opts)
map('n', 't4', '<Cmd>BufferGoto 4<CR>', opts)
map('n', 't5', '<Cmd>BufferGoto 5<CR>', opts)
map('n', 't6', '<Cmd>BufferGoto 6<CR>', opts)
map('n', 't7', '<Cmd>BufferGoto 7<CR>', opts)
map('n', 't8', '<Cmd>BufferGoto 8<CR>', opts)
map('n', 't9', '<Cmd>BufferGoto 9<CR>', opts)
map('n', 't0', '<Cmd>BufferLast<CR>', opts)
map('n', 'tc', '<Cmd>BufferClose<CR>', opts)

