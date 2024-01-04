local M = {}

local lsp = require("lspconfig")
local coq = require("coq")

function M.start_lsp()
	lsp.lua_ls.setup({ coq.lsp_ensure_capabilities() })
	lsp.rust_analyzer.setup({
		coq.lsp_ensure_capabilities({
			settings = {
				["rust-analyzer"] = {
					checkOnSave = {
						command = "clippy",
					},
				},
			},
		}),
	})

	lsp.gopls.setup({ coq.lsp_ensure_capabilities() })
	lsp.ruff_lsp.setup({ coq.lsp_ensure_capabilities() })
	lsp.jdtls.setup({ coq.lsp_ensure_capabilities() })
	lsp.clangd.setup({ coq.lsp_ensure_capabilities() })
	lsp.taplo.setup({ coq.lsp_ensure_capabilities() })
	lsp.fortls.setup({ coq.lsp_ensure_capabilities() })
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
