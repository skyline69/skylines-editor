local cwd = vim.fn.getcwd()
vim.opt.rtp:prepend(cwd)
package.path = table.concat({
	cwd .. "/lua/?.lua",
	cwd .. "/lua/?/init.lua",
	package.path,
}, ";")

local profile = require("user.profile")
require("user.setup_tui").open({
	profile = profile.default_minimal(),
	page = "qol",
})

vim.cmd("qa")
