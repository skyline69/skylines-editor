-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight on yank",
	group = vim.api.nvim_create_augroup("skyline-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})
