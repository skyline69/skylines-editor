-----------------------------------------------------------------------
--  Key-mappings (all from your old config)
-----------------------------------------------------------------------
local map = vim.keymap.set
local notify = function(msg)
	vim.notify(msg, vim.log.levels.WARN)
end

-- Clear search highlight
vim.api.nvim_set_keymap("n", "<Esc>", ":noh<CR><Esc>", { noremap = true, silent = true })

-- Telescope ----------------------------------------------------------
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "[F]ind [F]iles" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { desc = "[F]ind by [G]rep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "[F]ind [B]uffer" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "[F]ind [H]elp tags" })
map("n", "gd", "<cmd>Telescope lsp_definitions<CR>", { desc = "[G]oto [D]efinition" })

-- Nvim-tree toggle ---------------------------------------------------
map("n", "<leader>t", function()
	if not pcall(vim.cmd, "NvimTreeToggle") then
		notify("Nvim-tree not installed")
	end
end, { desc = "Toggle file tree", silent = true })

-- Format buffer (Conform) --------------------------------------------
map("n", "<leader>mf", function()
	pcall(require("conform").format, { async = true, lsp_fallback = true })
end, { desc = "Format buffer" })

-- Trouble diagnostics / references -----------------------------------
map("n", "<leader>xx", function()
	local ok, tr = pcall(require, "trouble")
	if ok then
		tr.toggle("diagnostics")
	else
		notify("Trouble not installed")
	end
end, { desc = "Diagnostics list" })

map("n", "gr", function()
	local ok, tr = pcall(require, "trouble")
	if ok then
		tr.toggle("lsp_references")
	else
		notify("Trouble not installed")
	end
end, { desc = "LSP references list" })

-- LazyGit ------------------------------------------------------------
map("n", "<leader>lg", function()
	if not pcall(vim.cmd, "LazyGit") then
		notify("LazyGit not installed")
	end
end, { desc = "Open LazyGit", silent = true })

-- Spectre search -----------------------------------------------------
map("n", "<leader>S", function()
	local ok, sp = pcall(require, "spectre")
	if ok then
		sp.toggle()
	else
		notify("Spectre not installed")
	end
end, { desc = "Toggle Spectre" })

-- Cokeline buffer / tab nav -----------------------------------------
map("n", "t<Left>", "<Plug>(cokeline-focus-prev)", { silent = true })
map("n", "t<Right>", "<Plug>(cokeline-focus-next)", { silent = true })
for i = 1, 9 do
	map("n", ("t%s"):format(i), ("<Plug>(cokeline-focus-%s)"):format(i), { silent = true })
end
map("n", "tc", ":bd<CR>", { desc = "Close buffer", silent = true })

-- Diffview -----------------------------------------------------------
map("n", "<leader>dv", "<cmd>DiffviewOpen<CR>", { desc = "[D]iff[V]iew open" })
