local palettes = {
	carbonfox = { sel0 = "#3F3351", fg3 = "#333333", green = "#03C988" },
}

local specs = {
	all = { syntax = { keyword = "magenta" } },
}

require("nightfox").setup({ palettes = palettes, specs = specs })
vim.o.background = "dark"
vim.cmd.colorscheme("carbonfox")

-- Tab-line tweaks
vim.api.nvim_set_hl(0, "TabLineSel", { fg = "#ffffff", bg = palettes.carbonfox.sel0, bold = true })
vim.api.nvim_set_hl(0, "TabLine", { fg = "#a0a0a0", bg = "NONE" })
vim.api.nvim_set_hl(0, "TabLineFill", { bg = "NONE" })

-- Auto-switch to Melange for TS/JS
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
	callback = function()
		vim.cmd.colorscheme("melange")
	end,
})
