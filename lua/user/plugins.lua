-----------------------------------------------------------------------
--  Bootstrap lazy.nvim
-----------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--branch=stable",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-----------------------------------------------------------------------
--  All plugin specs (Lazy.nvim)
-----------------------------------------------------------------------
require("lazy").setup({

	-- Guess-indent ------------------------------------------------------
	"NMAC427/guess-indent.nvim",

	-- Gitsigns ----------------------------------------------------------
	{
		"lewis6991/gitsigns.nvim",
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

	-- Telescope --------------------------------------------------------
	{
		"nvim-telescope/telescope.nvim",
		event = "VimEnter",
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
					-- show dot-files and other normally-ignored stuff
					file_ignore_patterns = {}, -- don’t ignore anything
				},
				pickers = {
					find_files = {
						hidden = true, -- include “.*”
						no_ignore = false, -- still respect .gitignore etc.
						follow = true, -- follow symlinks
					},
				},
				extensions = { ["ui-select"] = { require("telescope.themes").get_dropdown() } },
			})
			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "ui-select")
		end,
	},

	-- LSP - pulls in lsp.lua ------------------------------------------
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

	-- Conform formatter ------------------------------------------------
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

	-- blink.cmp (Super-tab completion) ---------------------------------
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

	-- Nightfox colour-scheme (+ tab-highlights & melange switch) -------
	{
		"EdenEast/nightfox.nvim",
		priority = 1000,
		config = function()
			require("user.colors")
		end,
	},

	-- Mini-modules (ai - surround - statusline) -----------------------
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

	-- Treesitter --------------------------------------------------------
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		main = "nvim-treesitter.configs",
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

	-- Nvim-tree ---------------------------------------------------------
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = "nvim-tree/nvim-web-devicons",
		opts = {
			sort = { sorter = "case_sensitive" },
			view = { width = 30, side = "right" },
			renderer = { group_empty = true },
			filters = { dotfiles = false },
		},
	},

	-- Diffview ----------------------------------------------------------
	{
		"sindrets/diffview.nvim",
		keys = { { "<leader>dv", "<cmd>DiffviewOpen<CR>", desc = "[D]iff[V]iew open" } },
		config = true,
	},

	-- Hex-viewer --------------------------------------------------------
	{ "RaafatTurki/hex.nvim", config = true },

	-- Todo-comments / Trouble / Spectre / Autoclose / Crates / LazyGit --
	{ "folke/todo-comments.nvim", event = "VimEnter", opts = {}, dependencies = "nvim-lua/plenary.nvim" },
	{ "folke/trouble.nvim", cmd = "Trouble", opts = {} },
	{ "nvim-pack/nvim-spectre", dependencies = "nvim-lua/plenary.nvim" },
	{ "m4xshen/autoclose.nvim", config = true },
	{ "saecki/crates.nvim", config = true },
	{
		"kdheepak/lazygit.nvim",
		cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile" },
		keys = { { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" } },
		dependencies = "nvim-lua/plenary.nvim",
	},
	{
		"goolord/alpha-nvim",
		event = "VimEnter", -- load only at launch
		dependencies = "nvim-tree/nvim-web-devicons",
		config = function() -- moved to its own file below, but
			require("user.alpha") -- keep this tiny one-liner here
		end,
	},

	{
		"willothy/nvim-cokeline",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			-- history for buffer layouts ↓
			"stevearc/resession.nvim",
		},
		config = true,
	},

	{
		"MeanderingProgrammer/render-markdown.nvim",
		-- dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" }, -- if you use the mini.nvim suite
		-- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },        -- if you use standalone mini plugins
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
		---@module 'render-markdown'
		---@type render.md.UserConfig
		opts = {},
	},

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
					on_attach = function(client, bufnr)
						vim.keymap.set("n", "<space>fp", ":ElixirFromPipe<cr>", { buffer = true, noremap = true })
						vim.keymap.set("n", "<space>tp", ":ElixirToPipe<cr>", { buffer = true, noremap = true })
						vim.keymap.set("v", "<space>em", ":ElixirExpandMacro<cr>", { buffer = true, noremap = true })
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

	-- Resession on its own so Lazy can see it explicitly ------------
	{ "stevearc/resession.nvim", opts = {} },
	{
		"rmagatti/auto-session",
		lazy = false,

		---enables autocomplete for opts
		---@module "auto-session"
		---@type AutoSession.Config
		opts = {
			suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
			-- log_level = 'debug',
		},
	},
}, { ui = { border = "rounded" } }) -- end of lazy.setup
