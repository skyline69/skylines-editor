local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

return require("lazy").setup({
	"lewis6991/gitsigns.nvim",
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons", optional = true },
	},
	"nvim-tree/nvim-tree.lua",
	"nvim-tree/nvim-web-devicons",
	"nvim-lua/plenary.nvim",
	"nvim-telescope/telescope.nvim",
	{
		"willothy/nvim-cokeline",
		dependencies = {
			"nvim-lua/plenary.nvim", -- Required for v0.4.0+
			"nvim-tree/nvim-web-devicons", -- If you want devicons
			"stevearc/resession.nvim", -- Optional, for persistent history
		},
		config = true,
	},
	"williamboman/mason.nvim",
	"williamboman/mason-lspconfig.nvim",
	"neovim/nvim-lspconfig",
	"saecki/crates.nvim",
	"nvim-treesitter/nvim-treesitter",
	"goolord/alpha-nvim",
	"numToStr/Comment.nvim",
	"windwp/nvim-autopairs",
	"karb94/neoscroll.nvim",
	"RaafatTurki/hex.nvim",
	"stevearc/conform.nvim",
	"lukas-reineke/indent-blankline.nvim",
	"luisiacc/gruvbox-baby",
	"kdheepak/lazygit.nvim",
	"ellisonleao/glow.nvim",
	"norcalli/nvim-colorizer.lua",
	"zbirenbaum/copilot.lua",
	{
		"folke/trouble.nvim",
		dependencies = "nvim-tree/nvim-web-devicons",
	},
	{
		"filipdutescu/renamer.nvim",
		branch = "master",
		dependencies = { "nvim-lua/plenary.nvim" },
	},
	{
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-cmdline",
		"hrsh7th/nvim-cmp",
		"L3MON4D3/LuaSnip",
		"saadparwaiz1/cmp_luasnip",
	},
	{
		"mrded/nvim-lsp-notify",
		dependencies = "rcarriga/nvim-notify",
	},
	"EdenEast/nightfox.nvim",
	"eandrju/cellular-automaton.nvim",
	"windwp/nvim-ts-autotag",
  "nvim-treesitter/nvim-treesitter-context",
  "petertriho/nvim-scrollbar"
})
