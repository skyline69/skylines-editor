-----------------------------------------------------------------------
--  Key-mappings (all from your old config)
-----------------------------------------------------------------------
local map = vim.keymap.set
local notify = function(msg)
	vim.notify(msg, vim.log.levels.WARN)
end
local load_plugin = function(plugin)
	local ok, lazy = pcall(require, "lazy")
	if ok then
		lazy.load({ plugins = { plugin } })
	end
end
local telescope = function(picker_name)
	return function()
		local ok, builtin = pcall(require, "telescope.builtin")
		if not ok then
			load_plugin("telescope.nvim")
			ok, builtin = pcall(require, "telescope.builtin")
		end
		if ok then
			builtin[picker_name]()
		else
			notify("Telescope not installed")
		end
	end
end
local feed_plug = function(keys, missing_msg)
	return function()
		if pcall(require, "cokeline") then
			local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
			vim.api.nvim_feedkeys(termcodes, "m", false)
		else
			notify(missing_msg)
		end
	end
end

-- Clear search highlight
vim.api.nvim_set_keymap("n", "<Esc>", ":noh<CR><Esc>", { noremap = true, silent = true })

-- Telescope ----------------------------------------------------------
map("n", "<leader>ff", telescope("find_files"), { desc = "[F]ind [F]iles" })
map("n", "<leader>fg", telescope("live_grep"), { desc = "[F]ind by [G]rep" })
map("n", "<leader>fb", telescope("buffers"), { desc = "[F]ind [B]uffer" })
map("n", "<leader>fh", telescope("help_tags"), { desc = "[F]ind [H]elp tags" })
map("n", "gd", telescope("lsp_definitions"), { desc = "[G]oto [D]efinition" })

-- Nvim-tree toggle ---------------------------------------------------
map("n", "<leader>t", function()
	load_plugin("nvim-tree.lua")
	if not pcall(vim.cmd, "NvimTreeToggle") then
		notify("Nvim-tree not installed")
	end
end, { desc = "Toggle file tree", silent = true })

-- Format buffer (Conform) --------------------------------------------
map("n", "<leader>mf", function()
	local ok, conform = pcall(require, "conform")
	if ok then
		conform.format({ async = true, lsp_fallback = true })
	else
		notify("Conform not installed")
	end
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
map("n", "t<Left>", feed_plug("<Plug>(cokeline-focus-prev)", "Cokeline not installed"), { silent = true })
map("n", "t<Right>", feed_plug("<Plug>(cokeline-focus-next)", "Cokeline not installed"), { silent = true })
for i = 1, 9 do
	map("n", ("t%s"):format(i), feed_plug(("<Plug>(cokeline-focus-%s)"):format(i), "Cokeline not installed"), { silent = true })
end
map("n", "tc", ":bd<CR>", { desc = "Close buffer", silent = true })

-- Diffview -----------------------------------------------------------
map("n", "<leader>dv", "<cmd>DiffviewOpen<CR>", { desc = "[D]iff[V]iew open" })
