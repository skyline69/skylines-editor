local cwd = vim.fn.getcwd()
vim.opt.rtp:prepend(cwd)
package.path = table.concat({
	cwd .. "/lua/?.lua",
	cwd .. "/lua/?/init.lua",
	package.path,
}, ";")

local ui = require("user.ui")

local notify_opts = ui.notify_opts()
assert(notify_opts.render == "wrapped-compact", "notify should keep the compact render style")
assert(notify_opts.top_down == true, "notify should stack from the top-right")
assert(notify_opts.timeout == 2500, "notify should keep the current timeout")

local notifications = {}
local original_notify = vim.notify
package.loaded.notify = {
	setup = function(opts)
		notifications[#notifications + 1] = opts
	end,
}

ui.setup_notify(notify_opts)

assert(#notifications == 1, "setup_notify should configure nvim-notify once")
assert(vim.notify == package.loaded.notify, "setup_notify should replace vim.notify")

vim.notify = original_notify
package.loaded.notify = nil

local noice_opts = ui.noice_opts()
assert(noice_opts.lsp.progress.enabled == true, "noice should keep LSP progress tracking enabled")

local has_skip_route = false
for _, route in ipairs(noice_opts.routes or {}) do
	if route.filter and route.filter.event == "lsp" and route.filter.kind == "progress" then
		has_skip_route = route.opts and route.opts.skip == true
		break
	end
end

assert(has_skip_route, "noice should continue suppressing popup rendering for LSP progress")
assert(noice_opts.presets.command_palette == true, "noice should keep the command palette preset")
