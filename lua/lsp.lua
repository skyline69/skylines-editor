local M = {}

local lsp = require("lspconfig")
local cmp = require("cmp")

cmp.config.formatting = {
	format = require("tailwindcss-colorizer-cmp").formatter,
}

require('pest-vim').setup {}


function M.start_lsp()
	lsp.lua_ls.setup({})
	lsp.rust_analyzer.setup({
		settings = {
			["rust-analyzer"] = {
				checkOnSave = {
					allFeatures = true,
					overrideCommand = {
						"cargo",
						"clippy",
						"--workspace",
						"--message-format=json",
						"--all-targets",
						"--all-features",
					},
				},
			},
		},
	})

	lsp.gopls.setup({})
	lsp.ruff_lsp.setup({})
	lsp.jdtls.setup({})
	lsp.taplo.setup({})
	lsp.fortls.setup({})
	lsp.ccls.setup({})
	lsp.sqls.setup({})
	lsp.tsserver.setup({})
	lsp.zls.setup({})
	lsp.dockerls.setup({})
	lsp.cssls.setup({})
	lsp.html.setup({})
	lsp.svelte.setup({})
	lsp.marksman.setup({})
	lsp.pest_ls.setup({})
	lsp.sourcekit.setup({
		cmd = { "sourcekit-lsp" },
		filetypes = { "swift", "objective-c", "objective-cpp" },
		root_dir = lsp.util.root_pattern("Package.swift", ".git"),
	})
	lsp.elixirls.setup({
		cmd = { "elixir-ls" },
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

M.start_lsp()

require("copilot").setup({
	panel = {
		enabled = true,
		auto_refresh = false,
		keymap = {
			jump_prev = "[[",
			jump_next = "]]",
			accept = "<CR>",
			refresh = "gr",
			open = "<M-CR>",
		},
		layout = {
			position = "bottom", -- | top | left | right
			ratio = 0.4,
		},
	},
	suggestion = {
		enabled = true,
		auto_trigger = true, -- Changed to true for automatic triggering
		debounce = 75,
		keymap = {
			accept = "<C-j>", -- Changed to Ctrl + J for accepting suggestions
			accept_word = false,
			accept_line = false,
		},
	},
	filetypes = {
		yaml = false,
		markdown = true,
		help = false,
		gitcommit = false,
		gitrebase = false,
		hgcommit = false,
		svn = false,
		cvs = false,
		["."] = false,
	},
	copilot_node_command = "node", -- Node.js version must be > 18.x
	server_opts_overrides = {},
})

return M
