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
assert(ensured.version == 4, "headless bootstrap should write the v4 schema")
assert(vim.deep_equal(ensured.features, { "core" }), "headless bootstrap should default to the minimal feature profile")
assert(vim.deep_equal(ensured.languages, {}), "headless bootstrap should not enable any languages")
assert(vim.tbl_contains(ensured.qol, "lualine"), "headless bootstrap should enable lualine by default")
assert(vim.deep_equal(ensured.disabled_qol, {}), "headless bootstrap should not disable any default QoL items")
assert(profile.exists(), "ensure() should persist the profile")

local migrated = profile.save({ version = 1, bundles = { "core", "search", "lsp" }, qol = { "crates" } })
assert(vim.deep_equal(migrated.features, { "core", "search", "lsp" }), "v1 bundle profiles should migrate into feature selections")
assert(vim.deep_equal(migrated.languages, {}), "v1 bundle profiles should default to no language selections")
assert(vim.deep_equal(migrated.qol, { "lualine" }), "migration should keep default-enabled QoL items while dropping invalid gated items")

local loaded = profile.load()
assert(loaded.version == 4, "saved profile should round-trip as schema version 4")
assert(vim.deep_equal(loaded.features, { "core", "search", "lsp" }), "saved profile should preserve selected features")
assert(vim.deep_equal(loaded.languages, {}), "saved profile should preserve selected languages")
assert(vim.tbl_contains(loaded.qol, "lualine"), "saved profile should preserve default-enabled QoL items")

local opted_out = profile.save({
	version = 4,
	features = { "core" },
	languages = {},
	qol = {},
	disabled_qol = { "lualine" },
})
assert(not vim.tbl_contains(opted_out.qol, "lualine"), "default-enabled QoL items should be removable through disabled_qol")
assert(vim.tbl_contains(opted_out.disabled_qol, "lualine"), "disabled default QoL items should round-trip")

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

local function find_repo(specs, repo)
	for _, spec in ipairs(specs) do
		if spec == repo or spec[1] == repo then
			return spec
		end
	end
	return nil
end

assert(not has_repo(minimal_specs, "neovim/nvim-lspconfig"), "minimal feature profile should omit LSP infrastructure")
assert(has_repo(language_specs, "neovim/nvim-lspconfig"), "language selections should pull in LSP infrastructure")
local lsp_spec = assert(find_repo(language_specs, "neovim/nvim-lspconfig"), "language selections should include the LSP spec")
assert(not has_repo(lsp_spec.dependencies or {}, "j-hui/fidget.nvim"), "language selections should not pull in fidget progress UI")
assert(has_repo(feature_specs, "nvim-telescope/telescope.nvim"), "feature selections should still add their plugins")
assert(has_repo(general_qol_specs, "windwp/nvim-autopairs"), "general QoL selections should add their plugins")
assert(not has_repo(general_qol_specs, "saecki/crates.nvim"), "language-gated QoL plugins should stay disabled without their language")
assert(has_repo(rust_qol_specs, "saecki/crates.nvim"), "language-gated QoL plugins should load once their language is selected")

cleanup()
