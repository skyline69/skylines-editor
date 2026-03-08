local M = {}
local languages = require("user.languages")
local qol = require("user.qol")

local bundles = {
	core = {
		label = "Core editing",
		description = "Lightweight editing helpers only.",
		specs = function()
			return {
				{
					"NMAC427/guess-indent.nvim",
					main = "guess-indent",
					opts = {
						auto_cmd = false,
						override_editorconfig = false,
					},
					config = function(_, opts)
						require("guess-indent").setup(opts)
						require("user.indent").setup()
					end,
				},
				{
					"echasnovski/mini.nvim",
					config = function()
						require("mini.ai").setup({ n_lines = 500 })
						require("mini.surround").setup()
						local st = require("mini.statusline")
						st.setup({ use_icons = vim.g.have_nerd_font })
						st.section_location = function()
							return "%2l:%-2v"
						end
					end,
				},
			}
		end,
	},
	ui = {
		label = "UI extras",
		description = "Dashboard, theme, icons, tabs, and session helpers.",
		specs = function()
			return {
				{
					"EdenEast/nightfox.nvim",
					priority = 1000,
					config = function()
						require("user.colors")
					end,
				},
				{
					"goolord/alpha-nvim",
					event = "VimEnter",
					cond = function()
						return vim.fn.argc() == 0
					end,
					dependencies = "nvim-tree/nvim-web-devicons",
					config = function()
						require("user.alpha")
					end,
				},
				{
					"willothy/nvim-cokeline",
					event = "VeryLazy",
					dependencies = {
						"nvim-lua/plenary.nvim",
						"nvim-tree/nvim-web-devicons",
						"stevearc/resession.nvim",
					},
					config = true,
				},
				{ "stevearc/resession.nvim", lazy = true, opts = {} },
				{
					"rmagatti/auto-session",
					event = "VeryLazy",
					opts = {
						suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
					},
				},
			}
		end,
	},
	search = {
		label = "Search and pickers",
		description = "Telescope and fuzzy finding.",
		specs = function()
			return {
				{
					"nvim-telescope/telescope.nvim",
					cmd = "Telescope",
					dependencies = {
						"nvim-lua/plenary.nvim",
						{
							"nvim-telescope/telescope-fzf-native.nvim",
							build = "make",
							cond = function()
								return vim.fn.executable("make") == 1
							end,
						},
						"nvim-telescope/telescope-ui-select.nvim",
						{ "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
					},
					config = function()
						require("telescope").setup({
							defaults = {
								file_ignore_patterns = {},
							},
							pickers = {
								find_files = {
									hidden = true,
									no_ignore = false,
									follow = true,
								},
							},
							extensions = {
								["ui-select"] = { require("telescope.themes").get_dropdown() },
							},
						})
						pcall(require("telescope").load_extension, "fzf")
						pcall(require("telescope").load_extension, "ui-select")
					end,
				},
			}
		end,
	},
	tree = {
		label = "File tree",
		description = "Nvim-tree sidebar navigation.",
		specs = function()
			return {
				{
					"nvim-tree/nvim-tree.lua",
					cmd = { "NvimTreeToggle", "NvimTreeOpen", "NvimTreeFindFile" },
					dependencies = "nvim-tree/nvim-web-devicons",
					opts = {
						sort = { sorter = "case_sensitive" },
						view = { width = 30, side = "right" },
						renderer = { group_empty = true },
						filters = { dotfiles = false },
					},
				},
			}
		end,
	},
	git = {
		label = "Git tools",
		description = "Signs, diffview, and LazyGit integration.",
		specs = function()
			return {
				{
					"lewis6991/gitsigns.nvim",
					event = { "BufReadPre", "BufNewFile" },
					opts = {
						signs = {
							add = { text = "+" },
							change = { text = "~" },
							delete = { text = "_" },
							topdelete = { text = "‾" },
							changedelete = { text = "~" },
						},
					},
				},
				{
					"sindrets/diffview.nvim",
					cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewFocusFiles", "DiffviewToggleFiles", "DiffviewRefresh" },
					config = true,
				},
				{
					"kdheepak/lazygit.nvim",
					cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile" },
					dependencies = "nvim-lua/plenary.nvim",
				},
			}
		end,
	},
	syntax = {
		label = "Syntax and markdown",
		description = "Treesitter plus markdown rendering.",
		specs = function()
			return {
				{
					"nvim-treesitter/nvim-treesitter",
					build = ":TSUpdate",
					main = "nvim-treesitter",
					opts = {
						ensure_installed = {
							"bash",
							"c",
							"diff",
							"html",
							"lua",
							"luadoc",
							"markdown",
							"markdown_inline",
							"query",
							"vim",
							"vimdoc",
						},
						auto_install = true,
						highlight = { enable = true, additional_vim_regex_highlighting = { "ruby" } },
						indent = { enable = false, disable = { "ruby" } },
					},
				},
				{
					"MeanderingProgrammer/render-markdown.nvim",
					ft = { "markdown" },
					dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
					opts = {},
				},
			}
		end,
	},
	lsp = {
		label = "LSP and formatting",
		description = "Language servers, completion, and formatters.",
		specs = function()
			return {
				{
					"neovim/nvim-lspconfig",
					dependencies = {
						{ "mason-org/mason.nvim", opts = {} },
						"mason-org/mason-lspconfig.nvim",
						"WhoIsSethDaniel/mason-tool-installer.nvim",
						{ "j-hui/fidget.nvim", opts = {} },
						"saghen/blink.cmp",
					},
					config = function()
						require("user.lsp")
					end,
				},
				{
					"stevearc/conform.nvim",
					event = { "BufWritePre" },
					opts = {
						formatters_by_ft = {
							lua = { "stylua" },
							yaml = { "yamlfmt" },
							yml = { "yamlfmt" },
							json = { "jq" },
							go = { "goimports", "golines" },
							python = { "black" },
							c = { "clang-format" },
							cpp = { "clang-format" },
						},
					},
				},
				{
					"saghen/blink.cmp",
					event = "InsertEnter",
					version = "1.*",
					dependencies = {
						{
							"L3MON4D3/LuaSnip",
							version = "2.*",
							build = (vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0) and nil or "make install_jsregexp",
							opts = {},
						},
					},
					opts = {
						keymap = { preset = "super-tab" },
						appearance = { nerd_font_variant = "mono" },
						completion = { documentation = { auto_show = true, auto_show_delay_ms = 500 } },
						sources = { default = { "lsp", "path", "snippets" } },
						snippets = { preset = "luasnip" },
						fuzzy = { implementation = "lua" },
						signature = { enabled = true },
					},
				},
			}
		end,
	},
	extras = {
		label = "Extra utilities",
		description = "Additional language helpers such as Elixir tools.",
		specs = function()
			return {
				{
					"elixir-tools/elixir-tools.nvim",
					version = "*",
					event = { "BufReadPre", "BufNewFile" },
					config = function()
						local elixir = require("elixir")
						local elixirls = require("elixir.elixirls")

						elixir.setup({
							nextls = { enable = true },
							elixirls = {
								enable = true,
								settings = elixirls.settings({
									dialyzerEnabled = false,
									enableTestLenses = false,
								}),
								on_attach = function(_, bufnr)
									vim.keymap.set("n", "<space>fp", ":ElixirFromPipe<cr>", { buffer = bufnr, noremap = true })
									vim.keymap.set("n", "<space>tp", ":ElixirToPipe<cr>", { buffer = bufnr, noremap = true })
									vim.keymap.set("v", "<space>em", ":ElixirExpandMacro<cr>", { buffer = bufnr, noremap = true })
								end,
							},
							projectionist = {
								enable = true,
							},
						})
					end,
					dependencies = {
						"nvim-lua/plenary.nvim",
					},
				},
			}
		end,
	},
}

local ordered_ids = { "core", "ui", "search", "tree", "git", "syntax", "lsp", "extras" }

function M.get_default_minimal()
	return { "core" }
end

function M.get_all()
	local result = {}
	for _, id in ipairs(ordered_ids) do
		local bundle = bundles[id]
		result[#result + 1] = {
			id = id,
			label = bundle.label,
			description = bundle.description,
		}
	end
	return result
end

function M.is_valid(id)
	return bundles[id] ~= nil
end

function M.resolve_plugins(enabled_ids, selected_languages, selected_qol)
	local specs = {}
	local seen = {}
	local resolved_languages = languages.resolve(selected_languages)
	local requested_ids = vim.deepcopy(enabled_ids or M.get_default_minimal())

	if #resolved_languages.languages > 0 and not vim.tbl_contains(requested_ids, "lsp") then
		requested_ids[#requested_ids + 1] = "lsp"
	end

	for _, id in ipairs(resolved_languages.required_features) do
		if not vim.tbl_contains(requested_ids, id) then
			requested_ids[#requested_ids + 1] = id
		end
	end

	for _, id in ipairs(requested_ids) do
		if bundles[id] and not seen[id] then
			seen[id] = true
			local bundle_specs = bundles[id].specs()
			for _, spec in ipairs(bundle_specs) do
				specs[#specs + 1] = spec
			end
		end
	end

	local resolved_qol = qol.resolve(selected_qol, selected_languages)
	for _, spec in ipairs(resolved_qol.specs) do
		specs[#specs + 1] = spec
	end

	return specs
end

return M
