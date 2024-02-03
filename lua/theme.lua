local palettes = {
	carbonfox = {
		sel0 = "#3F3351",
		fg3 = "#333333",
		green = "#03C988",
	},
}

local specs = {
	all = {
		syntax = {
			keyword = "magenta",
		},
	},
}

require("nightfox").setup({ palettes = palettes, specs = specs, groups = groups })
vim.api.nvim_create_autocmd("FileType", {
  pattern = "typescript",
  callback = function()
    vim.cmd.colorscheme 'melange'
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "typescriptreact",
  callback = function()
    vim.cmd.colorscheme 'melange'
  end,
})


vim.api.nvim_create_autocmd("FileType", {
  pattern = "javascript",
  callback = function()
    vim.cmd.colorscheme 'melange'
  end,
})

