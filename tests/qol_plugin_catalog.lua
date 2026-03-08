local cwd = vim.fn.getcwd()
vim.opt.rtp:prepend(cwd)
package.path = table.concat({
	cwd .. "/lua/?.lua",
	cwd .. "/lua/?/init.lua",
	package.path,
}, ";")

local bundles = require("user.bundles")
local profile = require("user.profile")
local qol = require("user.qol")

local function find_repo(specs, repo)
	for _, spec in ipairs(specs) do
		if spec == repo or spec[1] == repo then
			return spec
		end
	end
	return nil
end

for _, id in ipairs({
	"colorizer",
	"lualine",
	"illuminate",
	"undo_glow",
	"tsc",
	"ts_error_translator",
	"package_info",
	"commitmate",
}) do
	assert(qol.is_valid(id), ("QoL item %s should be registered"):format(id))
end

local ts_gated = qol.resolve({ "tsc", "ts_error_translator", "package_info" }, {}, {})
assert(not vim.tbl_contains(ts_gated.selected, "tsc"), "TypeScript helpers should stay disabled without the TypeScript language")
assert(not vim.tbl_contains(ts_gated.selected, "ts_error_translator"), "TypeScript error translation should stay disabled without the TypeScript language")
assert(not vim.tbl_contains(ts_gated.selected, "package_info"), "package-info should stay disabled without the TypeScript language")

local ts_enabled = qol.resolve({ "tsc", "ts_error_translator", "package_info" }, { "typescript" }, {})
assert(vim.tbl_contains(ts_enabled.selected, "tsc"), "TypeScript helpers should enable when TypeScript is selected")
assert(vim.tbl_contains(ts_enabled.selected, "ts_error_translator"), "TypeScript error translation should enable when TypeScript is selected")
assert(vim.tbl_contains(ts_enabled.selected, "package_info"), "package-info should enable when TypeScript is selected")
assert(find_repo(ts_enabled.specs, "dmmulroy/tsc.nvim"), "TypeScript helper should add tsc.nvim")
assert(find_repo(ts_enabled.specs, "dmmulroy/ts-error-translator.nvim"), "TypeScript helper should add ts-error-translator.nvim")
assert(find_repo(ts_enabled.specs, "vuki656/package-info.nvim"), "TypeScript helper should add package-info.nvim")

local git_gated = qol.resolve({ "commitmate" }, {}, {})
assert(not vim.tbl_contains(git_gated.selected, "commitmate"), "CommitMate should stay disabled without the Git feature")

local git_enabled = qol.resolve({ "commitmate" }, {}, { "core", "git" })
assert(vim.tbl_contains(git_enabled.selected, "commitmate"), "CommitMate should enable when the Git feature is selected")
assert(find_repo(git_enabled.specs, "ajatdarojat45/commitmate.nvim"), "CommitMate should add its plugin spec")

local general_qol_specs = bundles.resolve_plugins({ "core" }, {}, { "colorizer", "lualine", "illuminate", "undo_glow" })
assert(find_repo(general_qol_specs, "catgoose/nvim-colorizer.lua"), "General QoL should include colorizer")
assert(find_repo(general_qol_specs, "nvim-lualine/lualine.nvim"), "General QoL should include lualine")
assert(find_repo(general_qol_specs, "RRethy/vim-illuminate"), "General QoL should include vim-illuminate")
assert(find_repo(general_qol_specs, "y3owk1n/undo-glow.nvim"), "General QoL should include undo-glow")

local normalized = profile.normalize({
	version = 3,
	features = { "core" },
	languages = {},
	qol = { "commitmate", "tsc", "lualine" },
})
assert(vim.tbl_contains(normalized.qol, "lualine"), "Valid general QoL items should survive normalization")
assert(not vim.tbl_contains(normalized.qol, "commitmate"), "Feature-gated QoL items should be dropped without the required feature")
assert(not vim.tbl_contains(normalized.qol, "tsc"), "Language-gated QoL items should be dropped without the required language")

local core_specs = bundles.resolve_plugins({ "core" }, {}, {})
local mini_spec = assert(find_repo(core_specs, "echasnovski/mini.nvim"), "core bundle should include mini.nvim")

local original_qol = vim.g.skyline_active_qol
local statusline_calls = 0
package.loaded["mini.ai"] = { setup = function() end }
package.loaded["mini.surround"] = { setup = function() end }
package.loaded["mini.statusline"] = {
	setup = function()
		statusline_calls = statusline_calls + 1
	end,
}

vim.g.skyline_active_qol = {}
mini_spec.config()
assert(statusline_calls == 1, "mini.statusline should stay active when lualine is not selected")

statusline_calls = 0
vim.g.skyline_active_qol = { "lualine" }
mini_spec.config()
assert(statusline_calls == 0, "mini.statusline should not initialize when lualine is selected")

vim.g.skyline_active_qol = original_qol
