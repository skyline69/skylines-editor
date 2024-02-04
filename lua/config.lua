-- values
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.opt.listchars = {
	trail = "·",
}
vim.opt.clipboard = "unnamedplus" -- This is for using the system clipboard

-- booleans
vim.o.expandtab = true
vim.opt.termguicolors = true
vim.wo.relativenumber = true
vim.g.coq_settings = { auto_start = true }
vim.g.copilot_assume_mapped = true
vim.opt.list = true
vim.opt.spell = false
-- Functions
vim.loader.enable()
-- vim.cmd([[
--   autocmd FileType c setlocal tabstop=2 softtabstop=2 shiftwidth=2
-- ]])
vim.api.nvim_create_autocmd("FileType", {
  pattern = {"javascript", "typescript", "typescriptreact", "c", "lua", "css"},
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
  end
})

-- neovide --
if vim.g.neovide then
    -- Helper function for transparency formatting
    -- local alpha = function()
    --   return string.format("%x", math.floor(255 * vim.g.transparency or 0.8))
    -- end
    -- -- g:neovide_transparency should be 0 if you want to unify transparency of content and title bar.
    -- vim.g.neovide_transparency = 0.0
    -- vim.g.transparency = 0.97
    -- vim.g.neovide_background_color = "#0f1117" .. alpha()
    vim.g.neovide_cursor_antialiasing = true
    vim.g.neovide_cursor_vfx_mode = "pixiedust"
    vim.g.neovide_input_use_logo = 1
    vim.api.nvim_set_keymap('', '<D-v>', '+p<CR>', { noremap = true, silent = true})
    vim.api.nvim_set_keymap('!', '<D-v>', '<C-R>+', { noremap = true, silent = true})
    vim.api.nvim_set_keymap('t', '<D-v>', '<C-R>+', { noremap = true, silent = true})
    vim.api.nvim_set_keymap('v', '<D-v>', '<C-R>+', { noremap = true, silent = true})

end

-- Auto-stop LSP after not being used for 3 minutes --

local timer = nil
local timer_duration = (1000 * 60) * 10 -- in milliseconds
-- local lsp = require 'lsp'

local function stop_lsp()
  local clients = vim.lsp.get_active_clients()
  for _, client in ipairs(clients) do
    vim.lsp.stop_client(client.id)
  end
end

local function reset_timer()
  if timer then
    vim.loop.timer_stop(timer)
  else
    timer = vim.loop.new_timer()
  end

  --   -- Check if LSP clients are not active and start them
  -- if #vim.lsp.get_active_clients() == 0 then
  --   lsp.start_lsp()
  -- end
  --

  vim.loop.timer_start(timer, timer_duration, 0, function()
    stop_lsp()
    vim.loop.timer_stop(timer)
  end)
end

-- Reset the timer on various events
vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI", "TextChanged", "TextChangedI"}, {
  callback = reset_timer
})
