vim.cmd([[packadd packer.nvim]])

return require("packer").startup(function(use)
	use({
		"wbthomason/packer.nvim",
		-- "ellisonleao/gruvbox.nvim", -- theme
		"bluz71/vim-nightfly-colors", --theme
		"rstacruz/vim-closer",
		"lewis6991/gitsigns.nvim",
		{
			"nvim-lualine/lualine.nvim",
			requires = { "nvim-tree/nvim-web-devicons", opt = true },
		},
		"nvim-tree/nvim-tree.lua",
		"nvim-tree/nvim-web-devicons",
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
		"romgrk/barbar.nvim",
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
		"nyoom-engineering/oxocarbon.nvim",
		"ellisonleao/glow.nvim",
		"norcalli/nvim-colorizer.lua",
    "zbirenbaum/copilot.lua"
	})
end)

