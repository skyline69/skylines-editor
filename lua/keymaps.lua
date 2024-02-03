local builtin = require("telescope.builtin")

vim.g.mapleader = ","
vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
vim.keymap.set("n", "<leader>t", ":NvimTreeToggle<CR>", { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "<Esc>", ":noh<CR><Esc>", { noremap = true, silent = true })

local map = vim.api.nvim_set_keymap
local opts = { silent = true, noremap = true }

-- Tabs
map("n", "t<Left>", "<Plug>(cokeline-focus-prev)", opts)
map("n", "t<right>", "<Plug>(cokeline-focus-next)", opts)
for i = 1, 9 do
  map(
    "n",
    ("t%s"):format(i),
    ("<Plug>(cokeline-focus-%s)"):format(i),
    opts
  )
end
-- to close tabs do :bd
map("n", "tc", ":bd<CR>", opts)

-- trouble library
vim.keymap.set("n", "<leader>xx", function()
	require("trouble").toggle()
end)
vim.keymap.set("n", "<leader>xw", function()
	require("trouble").toggle("workspace_diagnostics")
end)
vim.keymap.set("n", "<leader>xd", function()
	require("trouble").toggle("document_diagnostics")
end)
vim.keymap.set("n", "<leader>xq", function()
	require("trouble").toggle("quickfix")
end)
vim.keymap.set("n", "<leader>xl", function()
	require("trouble").toggle("loclist")
end)
vim.keymap.set("n", "gr", function()
	require("trouble").toggle("lsp_references")
end)
vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)

-- Renamer
vim.api.nvim_set_keymap('i', '<F2>', '<cmd>lua require("renamer").rename()<cr>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>rn', '<cmd>lua require("renamer").rename()<cr>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<leader>rn', '<cmd>lua require("renamer").rename()<cr>', { noremap = true, silent = true })

-- LazyGit
vim.api.nvim_set_keymap('n', '<leader>gg', '<cmd>LazyGit<cr>', { noremap = true, silent = true })
