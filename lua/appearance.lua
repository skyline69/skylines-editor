vim.o.background = "dark" -- or "light" for light mode
vim.cmd.colorscheme "carbonfox"

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

require("lsp-notify").setup({
	notify = require("notify")
})
require("scrollbar").setup()
