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
--  Resolve active bundle profile before loading plugins
-----------------------------------------------------------------------
local profile = require("user.profile").ensure()
vim.g.skyline_active_bundles = profile.features
vim.g.skyline_active_languages = profile.languages
vim.g.skyline_active_qol = profile.qol

require("lazy").setup(require("user.bundles").resolve_plugins(profile.features, profile.languages, profile.qol), {
	ui = { border = "rounded" },
}) -- end of lazy.setup
