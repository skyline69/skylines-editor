-----------------------------------------------------------------------
--  LSP servers + formatter tooling
-----------------------------------------------------------------------

-- cmp capabilities:
-- On Nvim 0.11+ with vim.lsp.config, most completion plugins don’t require
-- manual capability merging. Keep this line if your cmp needs it; otherwise remove.
local maybe_caps = nil
pcall(function()
	maybe_caps = require("blink.cmp").get_lsp_capabilities()
end)

-- Define your servers (same content you had), just data:
local servers = {
	lua_ls = {
		settings = {
			Lua = { diagnostics = {
				globals = { "love", "vim" },
			}, completion = { callSnippet = "Replace" } },
		},
	},
	rust_analyzer = {},
	clangd = {
		cmd = { "clangd", "--compile-commands-dir=build" },
	},
	pyright = {},
	ts_ls = {},
	gopls = {},
	taplo = {},
	svelte = {},
	mesonlsp = {},
	sui_move_analyzer = {
		cmd = { "sui-move-analyzer" },
		filetypes = { "move" },
		root_markers = { "Move.toml", ".git" },
	},
	tailwindcss = {},
	dockerls = {},
	zls = {},
	jsonls = {},
	qmlls = {},
	html = {},
	csharp_ls = {},
	yamlls = {
		cmd = { "yaml-language-server", "--stdio" },
		filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab", "yaml.helm-values" },
		-- Use root markers with the native API instead of a root_dir() function
		root_markers = { ".git" },
		single_file_support = true,
		settings = {
			redhat = { telemetry = { enabled = false } },
		},
	},
}

-- Optional defaults merged into each server config
local defaults = {}
if maybe_caps then
	defaults.capabilities = maybe_caps
end

-- Register configs with the native API
for name, cfg in pairs(servers) do
	-- Merge your defaults into each server’s config
	local merged = vim.tbl_deep_extend("force", {}, defaults, cfg or {})
	vim.lsp.config[name] = merged
end

-- Ensure tools/servers are installed (Mason)
local fmt = {
	"stylua", -- Lua
	"clang-format", -- C / C++
	"yamlfmt", -- YAML
	"jq", -- JSON
	"goimports", -- Go
	"golines", -- Go
	"black", -- Python
	"csharpier",
}

local ignore_servers = { "sui_move_analyzer" }

local mason_servers = {}
for name, _ in pairs(servers) do
	if not vim.tbl_contains(ignore_servers, name) then
		table.insert(mason_servers, name)
	end
end

require("mason-tool-installer").setup({
	ensure_installed = vim.tbl_extend("force", mason_servers, fmt),
})

-- If you want Mason to auto-enable installed servers, you can also use mason-lspconfig
-- (not required). Otherwise, just enable explicitly:
vim.lsp.enable(vim.tbl_keys(servers))

-- macOS-only: enable SourceKit-LSP (not managed by Mason)
if vim.loop.os_uname().sysname == "Darwin" then
	vim.lsp.config.sourcekit = vim.tbl_deep_extend("force", {}, defaults, {
		cmd = { "sourcekit-lsp" }, -- requires Xcode or Swift toolchain
		filetypes = { "swift" },
		root_markers = { "Package.swift", ".git" },
	})
	vim.lsp.enable({ "sourcekit" })
end
