-----------------------------------------------------------------------
--  LSP servers + formatter tooling
-----------------------------------------------------------------------
local capabilities = require("blink.cmp").get_lsp_capabilities()

local servers = {
	lua_ls = { settings = { Lua = { completion = { callSnippet = "Replace" } } } },
	rust_analyzer = {},
	clangd = {},
	pyright = {},
	ts_ls = {},
	gopls = {},
	taplo = {},
	svelte = {},
	mesonlsp = {},
	tailwindcss = {},
	dockerls = {},
	zls = {},
	jsonls = {},
}

local formatters = {
	"stylua", -- Lua
	"clang-format", -- C / C++
	"yamlfmt", -- YAML
	"jq", -- JSON
	"goimports", -- Go
	"golines", -- Go
	"black", -- Python
}

require("mason-tool-installer").setup({
	ensure_installed = vim.tbl_extend("force", vim.tbl_keys(servers), formatters),
})

require("mason-lspconfig").setup({
	handlers = {
		function(name)
			local opts = servers[name] or {}
			opts.capabilities = vim.tbl_deep_extend("force", {}, capabilities, opts.capabilities or {})
			require("lspconfig")[name].setup(opts)
		end,
	},
})
