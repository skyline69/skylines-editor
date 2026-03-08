local cwd = vim.fn.getcwd()
vim.opt.rtp:prepend(cwd)
package.path = table.concat({
	cwd .. "/lua/?.lua",
	cwd .. "/lua/?/init.lua",
	package.path,
}, ";")

local uv = vim.uv or vim.loop
local profile_path = vim.fn.tempname() .. ".json"
vim.env.SKYLINE_PROFILE_PATH = profile_path

local function cleanup()
	uv.fs_unlink(profile_path)
end

cleanup()

local profile = require("user.profile")
local bundles = require("user.bundles")
local languages = require("user.languages")
local qol = require("user.qol")

assert(profile.exists() == false, "profile should not exist before ensure()")

local ensured = profile.ensure({ headless = true })
assert(ensured.version == 3, "headless bootstrap should write the v3 schema")
assert(vim.deep_equal(ensured.features, { "core" }), "headless bootstrap should default to the minimal feature profile")
assert(vim.deep_equal(ensured.languages, {}), "headless bootstrap should not enable any languages")
assert(vim.deep_equal(ensured.qol, {}), "headless bootstrap should not enable any QoL items")
assert(profile.exists(), "ensure() should persist the profile")

local migrated = profile.save({ version = 1, bundles = { "core", "search", "lsp" }, qol = { "crates" } })
assert(vim.deep_equal(migrated.features, { "core", "search", "lsp" }), "v1 bundle profiles should migrate into feature selections")
assert(vim.deep_equal(migrated.languages, {}), "v1 bundle profiles should default to no language selections")
assert(vim.deep_equal(migrated.qol, {}), "language-gated QoL items should be removed when their language is not selected")

local loaded = profile.load()
assert(loaded.version == 3, "saved profile should round-trip as schema version 3")
assert(vim.deep_equal(loaded.features, { "core", "search", "lsp" }), "saved profile should preserve selected features")
assert(vim.deep_equal(loaded.languages, {}), "saved profile should preserve selected languages")
assert(vim.deep_equal(loaded.qol, {}), "saved profile should preserve selected QoL items")

local selected_languages = { "lua", "python", "rust" }
local resolved = languages.resolve(selected_languages)
local expected_servers = { "lua_ls", "pyright", "rust_analyzer" }
local expected_tools = { "stylua", "black", "rust-analyzer" }

for _, server in ipairs(expected_servers) do
	assert(vim.tbl_contains(resolved.servers, server), ("language selection should enable %s"):format(server))
end

for _, tool in ipairs(expected_tools) do
	assert(vim.tbl_contains(resolved.mason_packages, tool), ("language selection should install %s"):format(tool))
end

local gated_qol = qol.resolve({ "autoclose", "crates" }, {})
assert(vim.tbl_contains(gated_qol.selected, "autoclose"), "general QoL items should resolve without languages")
assert(not vim.tbl_contains(gated_qol.selected, "crates"), "language-specific QoL items should stay disabled without their language")

local rust_qol = qol.resolve({ "autoclose", "crates" }, { "rust" })
assert(vim.tbl_contains(rust_qol.selected, "crates"), "language-specific QoL items should activate when their language is selected")

local minimal_specs = bundles.resolve_plugins({ "core" }, {})
local language_specs = bundles.resolve_plugins({ "core" }, { "lua" }, {})
local feature_specs = bundles.resolve_plugins({ "core", "search" }, { "lua" }, {})
local general_qol_specs = bundles.resolve_plugins({ "core" }, {}, { "autoclose" })
local rust_qol_specs = bundles.resolve_plugins({ "core" }, { "rust" }, { "crates" })

local function has_repo(specs, repo)
	for _, spec in ipairs(specs) do
		if spec == repo or spec[1] == repo then
			return true
		end
	end
	return false
end

assert(not has_repo(minimal_specs, "neovim/nvim-lspconfig"), "minimal feature profile should omit LSP infrastructure")
assert(has_repo(language_specs, "neovim/nvim-lspconfig"), "language selections should pull in LSP infrastructure")
assert(has_repo(feature_specs, "nvim-telescope/telescope.nvim"), "feature selections should still add their plugins")
assert(has_repo(general_qol_specs, "windwp/nvim-autopairs"), "general QoL selections should add their plugins")
assert(not has_repo(general_qol_specs, "saecki/crates.nvim"), "language-gated QoL plugins should stay disabled without their language")
assert(has_repo(rust_qol_specs, "saecki/crates.nvim"), "language-gated QoL plugins should load once their language is selected")

cleanup()
