-----------------------------------------------------------------------
--  LSP servers + formatter tooling
-----------------------------------------------------------------------
local profile = require("user.profile").ensure()
local selected = require("user.languages").resolve(profile.languages)

local maybe_caps = nil
pcall(function()
	maybe_caps = require("blink.cmp").get_lsp_capabilities()
end)

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

for _, name in ipairs(selected.servers) do
	local cfg = servers[name]
	if cfg then
		local merged = vim.tbl_deep_extend("force", {}, defaults, cfg)
		vim.lsp.config[name] = merged
	end
end

local mason_packages = vim.deepcopy(selected.mason_packages)
if vim.tbl_contains(vim.g.skyline_active_bundles or {}, "syntax") then
	table.insert(mason_packages, "tree-sitter-cli")
end

require("mason-tool-installer").setup({
	ensure_installed = mason_packages,
})

if #selected.servers > 0 then
	vim.lsp.enable(selected.servers)
end
