-----------------------------------------------------------------------
-- 0. LEADER
-----------------------------------------------------------------------
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-----------------------------------------------------------------------
-- 1. BASIC OPTIONS
-----------------------------------------------------------------------
vim.g.have_nerd_font = true
local opt = vim.opt

opt.breakindent = true
opt.clipboard = "unnamedplus"
opt.cursorline = false
opt.fillchars = { eob = " " }
opt.foldlevelstart = 200
opt.formatoptions:remove("t")
opt.ignorecase = true
opt.inccommand = "split"
opt.mouse = "a"
opt.number = true
opt.relativenumber = true
opt.scrolloff = 3
opt.shiftwidth = 4
opt.signcolumn = "yes"
opt.smartcase = true
opt.splitbelow = true
opt.splitright = true
opt.tabstop = 4
opt.termguicolors = true
opt.timeoutlen = 3000
opt.undofile = true
opt.updatetime = 250
opt.wrap = false

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
