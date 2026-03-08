local M = {}

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
}

local ordered_ids = {
	"autoclose",
	"todo_comments",
	"trouble",
	"spectre",
	"hex",
	"crates",
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
		}
	end
	return result
end

function M.is_valid(id)
	return items[id] ~= nil
end

local function languages_available(required_languages, selected_languages)
	if not required_languages or #required_languages == 0 then
		return true
	end

	for _, language in ipairs(required_languages) do
		if not vim.tbl_contains(selected_languages or {}, language) then
			return false
		end
	end

	return true
end

function M.resolve(selected_qol, selected_languages)
	local selected = {}
	local specs = {}
	local seen_qol = {}

	for _, id in ipairs(selected_qol or {}) do
		local item = items[id]
		if item and not seen_qol[id] and languages_available(item.requires_languages, selected_languages) then
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

function M.is_available(id, selected_languages)
	local item = items[id]
	if not item then
		return false
	end
	return languages_available(item.requires_languages, selected_languages)
end

return M
