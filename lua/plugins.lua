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
	-- "ellisonleao/gruvbox.nvim", -- theme
	"bluz71/vim-nightfly-colors", --theme
	"rstacruz/vim-closer",
	"lewis6991/gitsigns.nvim",
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons", optional = true },
	},
	"nvim-tree/nvim-tree.lua",
	"nvim-tree/nvim-web-devicons",
	"nvim-lua/plenary.nvim",
	"nvim-telescope/telescope.nvim",
	-- "romgrk/barbar.nvim",
	{
		"willothy/nvim-cokeline",
		dependencies = {
			"nvim-lua/plenary.nvim", -- Required for v0.4.0+
			"nvim-tree/nvim-web-devicons", -- If you want devicons
			"stevearc/resession.nvim", -- Optional, for persistent history
		},
		config = true,
	},
	"ms-jpq/coq_nvim",
	"ms-jpq/coq.artifacts",
	"ms-jpq/coq.thirdparty",
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
	"nyoom-engineering/oxocarbon.nvim",
	"kdheepak/lazygit.nvim",
	-- "EdenEast/nightfox.nvim",
	"ellisonleao/glow.nvim",
	"norcalli/nvim-colorizer.lua",
	"zbirenbaum/copilot.lua",
	{
		"folke/trouble.nvim",
		dependencies = "nvim-tree/nvim-web-devicons",
	},
	"j-hui/fidget.nvim",
	{
		"filipdutescu/renamer.nvim",
		branch = "master",
		dependencies = { "nvim-lua/plenary.nvim" },
	},
	-- "HiPhish/nvim-ts-rainbow2",
	-- "mrded/nvim-lsp-notify",
})
