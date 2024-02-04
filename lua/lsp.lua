local M = {}

local lsp = require("lspconfig")

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
	lsp.clangd.setup({})
	lsp.taplo.setup({})
	lsp.fortls.setup({})
	lsp.sqls.setup({})
	lsp.tsserver.setup({})
	lsp.zls.setup({})
	lsp.dockerls.setup({})
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
