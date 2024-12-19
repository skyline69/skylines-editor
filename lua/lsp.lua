local M = {}

local lsp = require("lspconfig")
-- local cmp = require("cmp")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- cmp.config.formatting = {
-- 	format = require("tailwindcss-colorizer-cmp").formatter,
-- }

for _, method in ipairs({ "textDocument/diagnostic", "workspace/diagnostic" }) do
	local default_diagnostic_handler = vim.lsp.handlers[method]
	vim.lsp.handlers[method] = function(err, result, context, config)
		if err ~= nil and err.code == -32802 then
			return
		end
		return default_diagnostic_handler(err, result, context, config)
	end
end

require("pest-vim").setup({})

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
	lsp.ruff.setup({})
	lsp.jdtls.setup({})
	lsp.taplo.setup({})
	lsp.fortls.setup({})
	lsp.clangd.setup({
		cmd = { "clangd" },
		capabilities = capabilities,
	})
	lsp.ts_ls.setup({
		on_attach = on_attach,
		root_dir = lsp.util.root_pattern("package.json"),
		single_file_support = false,
	})
	lsp.sqls.setup({})
	lsp.zls.setup({})
	lsp.dockerls.setup({})
	lsp.cssls.setup({})
	lsp.eslint.setup({})
	lsp.html.setup({})
	lsp.svelte.setup({})
	lsp.slint_lsp.setup({
		cmd = {
			"/opt/homebrew/opt/llvm/bin/clangd",
			"--background-index",
			"--clang-tidy",
			"--completion-style=llvm",
			"--header-insertion=iwyu",
			"--header-insertion-decorators",
			"--function-arg-placeholders",
			"--fallback-style=llvm",
			"--suggest-missing-includes",
			"--cross-file-rename",
		},
	})
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
	lsp.mesonlsp.setup({})
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
