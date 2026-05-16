-----------------------------------------------------------------------
--  LSP servers + formatter tooling
-----------------------------------------------------------------------
local profile = require("user.profile").ensure()
local selected = require("user.languages").resolve(profile.languages)

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

for _, name in ipairs(selected.servers) do
	local cfg = servers[name]
	if cfg then
		vim.lsp.config[name] = cfg
	end
end

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("SkylineBlinkCaps", { clear = true }),
	callback = function(args)
		local ok, blink = pcall(require, "blink.cmp")
		if not ok or type(blink.get_lsp_capabilities) ~= "function" then
			return
		end
		local client = vim.lsp.get_client_by_id(args.data and args.data.client_id)
		if not client then
			return
		end
		client.server_capabilities =
			vim.tbl_deep_extend("force", client.server_capabilities or {}, blink.get_lsp_capabilities())
	end,
})

local mason_packages = vim.deepcopy(selected.mason_packages)
if vim.tbl_contains(vim.g.skyline_active_bundles or {}, "syntax") then
	table.insert(mason_packages, "tree-sitter-cli")
end

vim.api.nvim_create_autocmd("User", {
	pattern = "VeryLazy",
	once = true,
	callback = function()
		require("mason-tool-installer").setup({
			ensure_installed = mason_packages,
		})
	end,
})

if #selected.servers > 0 then
	vim.lsp.enable(selected.servers)
end
