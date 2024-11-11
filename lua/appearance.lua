vim.o.background = "dark" -- or "light" for light mode
vim.cmd.colorscheme("carbonfox")

local alpha = require("alpha")
local dashboard = require("alpha.themes.dashboard")

-- Set header
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

-- Set menu
dashboard.section.buttons.val = {
	dashboard.button("e", "  > New file", ":ene <BAR> startinsert <CR>"),
	dashboard.button("f", "󰈞  > Find file", ":call OpenTelescopeInWorkspace()<CR>"),
	dashboard.button("r", "  > Recent", ":Telescope oldfiles<CR>"),
	dashboard.button("s", "  > Settings", ":e $MYVIMRC | :cd %:p:h | split . | wincmd k<CR>"),
	dashboard.button("q", "󰗼  > Quit NVIM", ":qa<CR>"),
}

alpha.setup(dashboard.opts)

-- Disable folding on alpha buffer
vim.cmd([[
    autocmd FileType alpha setlocal nofoldenable
]])

vim.cmd([[
function! OpenTelescopeInWorkspace()
    cd $HOME/Workspace
    lua require('telescope.builtin').find_files()
endfunction
]])

require("colorizer").setup()

-- OLD START
-- require("lsp-notify").setup({
-- 	notify = require("notify"),
-- })
-- OLD END

require("fidget").setup()

-- discord rich presence

-- The setup config table shows all available config options with their default values:
require("presence").setup({
	-- General options
	auto_update = true,
	neovim_image_text = "Skyline's Editor",
	main_image = "file",
	client_id = "793271441293967371",
	log_level = nil,
	debounce_timeout = 10,
	enable_line_number = false,
	blacklist = {},
	buttons = false,
	file_assets = {},
	show_time = true,

	-- Rich Presence text options
	editing_text = "Coding right now",
	file_explorer_text = "Browsing",
	git_commit_text = "Committing changes",
	plugin_manager_text = "Currently managing plugins",
	reading_text = "Currently Reading",
	workspace_text = "Currently Working",
	line_number_text = "",
})

require("nvim-tree").setup({
	view = {
		side = "right",
	},
})

require("ibl").setup({})

