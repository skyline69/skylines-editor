local M = {}
local default_enabled_ids = {
	lualine = true,
}

local items = {
	autoclose = {
		label = "Autoclose",
		description = "Smart bracket, quote, and newline pairing.",
		specs = {
			{
				"windwp/nvim-autopairs",
				event = "InsertEnter",
				opts = {
					check_ts = true,
					enable_check_bracket_line = false,
					disable_filetype = { "TelescopePrompt", "spectre_panel" },
				},
			},
		},
	},
	todo_comments = {
		label = "Todo comments",
		description = "Highlight and search TODO/FIXME style comments.",
		specs = {
			{ "folke/todo-comments.nvim", event = "VimEnter", opts = {}, dependencies = "nvim-lua/plenary.nvim" },
		},
	},
	trouble = {
		label = "Trouble",
		description = "Diagnostics and references lists.",
		specs = {
			{ "folke/trouble.nvim", cmd = "Trouble", opts = {} },
		},
	},
	spectre = {
		label = "Spectre",
		description = "Project-wide search and replace.",
		specs = {
			{ "nvim-pack/nvim-spectre", dependencies = "nvim-lua/plenary.nvim" },
		},
	},
	hex = {
		label = "Hex viewer",
		description = "Inspect binary buffers in hex.",
		specs = {
			{ "RaafatTurki/hex.nvim", config = true },
		},
	},
	crates = {
		label = "Crates.nvim",
		description = "Cargo.toml dependency helpers for Rust.",
		requires_languages = { "rust" },
		specs = {
			{ "saecki/crates.nvim", config = true },
		},
	},
	colorizer = {
		label = "Colorizer",
		description = "Highlight inline color values.",
		specs = {
			{
				"catgoose/nvim-colorizer.lua",
				ft = { "css", "scss", "sass", "html", "javascript", "javascriptreact", "typescript", "typescriptreact", "svelte", "vue", "lua" },
				opts = {
					user_commands = false,
					filetypes = { "css", "scss", "sass", "html", "javascript", "javascriptreact", "typescript", "typescriptreact", "svelte", "vue", "lua" },
					options = {
						parsers = {
							css = true,
							names = { enable = true },
							tailwind = { enable = true },
						},
					},
				},
			},
		},
	},
	lualine = {
		label = "Lualine",
		description = "Richer statusline with project context, diagnostics, and git info.",
		note = "Replaces the default statusline",
		specs = {
			{
				"nvim-lualine/lualine.nvim",
				event = "VeryLazy",
				dependencies = { "nvim-tree/nvim-web-devicons" },
				opts = function()
					return require("user.statusline").opts()
				end,
			},
		},
	},
	illuminate = {
		label = "Illuminate",
		description = "Highlight other uses of the word under the cursor.",
		specs = {
			{
				"RRethy/vim-illuminate",
				event = { "BufReadPost", "BufNewFile" },
				config = function()
					require("illuminate").configure({
						delay = 200,
						disable_keymaps = true,
						large_file_cutoff = 5000,
						filetypes_denylist = { "alpha", "NvimTree", "TelescopePrompt", "checkhealth", "lazy", "mason" },
					})
				end,
			},
		},
	},
	undo_glow = {
		label = "Undo glow",
		description = "Animated feedback for undo, redo, and paste.",
		specs = {
			{
				"y3owk1n/undo-glow.nvim",
				version = "*",
				opts = {
					animation = {
						enabled = true,
						duration = 250,
						animation_type = "fade",
						window_scoped = true,
					},
				},
				keys = {
					{
						"u",
						function()
							require("undo-glow").undo()
						end,
						mode = "n",
						desc = "Undo with highlight",
					},
					{
						"<C-r>",
						function()
							require("undo-glow").redo()
						end,
						mode = "n",
						desc = "Redo with highlight",
					},
					{
						"p",
						function()
							require("undo-glow").paste_below()
						end,
						mode = "n",
						desc = "Paste below with highlight",
					},
					{
						"P",
						function()
							require("undo-glow").paste_above()
						end,
						mode = "n",
						desc = "Paste above with highlight",
					},
				},
			},
		},
	},
	tsc = {
		label = "TSC",
		description = "Project-wide TypeScript type-checking.",
		requires_languages = { "typescript" },
		specs = {
			{
				"dmmulroy/tsc.nvim",
				cmd = { "TSC", "TSCOpen", "TSCClose", "TSCStop" },
				ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
				config = function()
					require("tsc").setup({
						use_diagnostics = true,
					})
				end,
			},
		},
	},
	ts_error_translator = {
		label = "TS error translator",
		description = "Translate TypeScript diagnostics into plain English.",
		requires_languages = { "typescript" },
		specs = {
			{
				"dmmulroy/ts-error-translator.nvim",
				ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
				config = function()
					require("ts-error-translator").setup({
						auto_attach = true,
						servers = { "ts_ls" },
					})
				end,
			},
		},
	},
	package_info = {
		label = "Package info",
		description = "Inspect and update npm package versions in package.json.",
		requires_languages = { "typescript" },
		specs = {
			{
				"vuki656/package-info.nvim",
				ft = { "json" },
				dependencies = { "MunifTanjim/nui.nvim" },
				keys = {
					{
						"<leader>ns",
						function()
							require("package-info").show()
						end,
						desc = "Show package versions",
					},
					{
						"<leader>nd",
						function()
							require("package-info").delete()
						end,
						desc = "Delete package dependency",
					},
					{
						"<leader>np",
						function()
							require("package-info").change_version()
						end,
						desc = "Change package version",
					},
					{
						"<leader>ni",
						function()
							require("package-info").install()
						end,
						desc = "Install package dependency",
					},
				},
				config = function()
					require("package-info").setup({
						autostart = true,
					})
				end,
			},
		},
	},
	commitmate = {
		label = "CommitMate",
		description = "Generate commit messages with Copilot Chat.",
		requires_features = { "git" },
		specs = {
			{
				"ajatdarojat45/commitmate.nvim",
				cmd = { "CommitMate" },
				dependencies = {
					"nvim-lua/plenary.nvim",
					{
						"CopilotC-Nvim/CopilotChat.nvim",
						build = "make tiktoken",
						dependencies = {
							"nvim-lua/plenary.nvim",
						},
						opts = {},
					},
				},
				keys = {
					{ "<leader>cm", "<cmd>CommitMate<cr>", desc = "Generate commit message" },
				},
				config = function()
					require("commitmate").setup({
						open_lazygit = false,
					})
				end,
			},
		},
	},
}

local ordered_ids = {
	"autoclose",
	"todo_comments",
	"trouble",
	"spectre",
	"hex",
	"crates",
	"colorizer",
	"lualine",
	"illuminate",
	"undo_glow",
	"tsc",
	"ts_error_translator",
	"package_info",
	"commitmate",
}

function M.get_all()
	local result = {}
	for _, id in ipairs(ordered_ids) do
		local item = items[id]
		result[#result + 1] = {
			id = id,
			label = item.label,
			description = item.description,
			requires_languages = item.requires_languages,
			requires_features = item.requires_features,
			note = item.note,
		}
	end
	return result
end

function M.is_valid(id)
	return items[id] ~= nil
end

function M.default_selected()
	local selected = {}
	for _, id in ipairs(ordered_ids) do
		if default_enabled_ids[id] then
			selected[#selected + 1] = id
		end
	end
	return selected
end

function M.is_default_enabled(id)
	return default_enabled_ids[id] == true
end

local function requirements_available(required, selected)
	if not required or #required == 0 then
		return true
	end

	for _, value in ipairs(required) do
		if not vim.tbl_contains(selected or {}, value) then
			return false
		end
	end

	return true
end

local function available(item, selected_languages, selected_features)
	return requirements_available(item.requires_languages, selected_languages)
		and requirements_available(item.requires_features, selected_features)
end

function M.resolve(selected_qol, selected_languages, selected_features)
	local selected = {}
	local specs = {}
	local seen_qol = {}

	for _, id in ipairs(selected_qol or {}) do
		local item = items[id]
		if item and not seen_qol[id] and available(item, selected_languages, selected_features) then
			seen_qol[id] = true
			selected[#selected + 1] = id
			for _, spec in ipairs(item.specs or {}) do
				specs[#specs + 1] = spec
			end
		end
	end

	return {
		selected = selected,
		specs = specs,
	}
end

function M.is_available(id, selected_languages, selected_features)
	local item = items[id]
	if not item then
		return false
	end
	return available(item, selected_languages, selected_features)
end

return M
