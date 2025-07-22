-- luacheck: globals vim
local alpha = require("alpha")
local dashboard = require("alpha.themes.dashboard")

dashboard.section.header.val = {
	"╔════════════════════════════════════════════════════════════════════════╗",
	"║         __         ___           _                   ___ __            ║",
	"║   _____/ /____  __/ (_)___  ___ ( )_____   ___  ____/ (_) /_____  _____║",
	"║  / ___/ //_/ / / / / / __ \\/ _ \\|// ___/  / _ \\/ __  / / __/ __ \\/ ___/║",
	"║ (__  ) ,< / /_/ / / / / / /  __/ (__  )  /  __/ /_/ / / /_/ /_/ / /    ║",
	"║/____/_/|_|\\__, /_/_/_/ /_/\\___/ /____/   \\___/\\__,_/_/\\__/\\____/_/     ║",
	"║          /____/                                                        ║",
	"╚════════════════════════════════════════════════════════════════════════╝",
}

dashboard.section.buttons.val = {
	dashboard.button("e", "  > New file", ":ene <BAR> startinsert <CR>"),
	dashboard.button("f", "󰈞  > Find file", ":lua require('telescope.builtin').find_files()<CR>"),
	dashboard.button("r", "  > Recent", ":Telescope oldfiles<CR>"),
	dashboard.button("s", "  > Settings", ":e $MYVIMRC <CR>"),
	dashboard.button("q", "󰗼  > Quit", ":qa<CR>"),
}

alpha.setup(dashboard.opts)

-- No folds in the dashboard buffer
vim.api.nvim_create_autocmd("FileType", {
	pattern = "alpha",
	callback = function()
		vim.opt_local.foldenable = false
	end,
})
