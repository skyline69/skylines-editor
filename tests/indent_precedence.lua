local cwd = vim.fn.getcwd()
vim.opt.rtp:prepend(cwd)
package.path = table.concat({
	cwd .. "/lua/?.lua",
	cwd .. "/lua/?/init.lua",
	package.path,
}, ";")

local bundles = require("user.bundles")

local function find_repo(specs, repo)
	for _, spec in ipairs(specs) do
		if spec == repo or spec[1] == repo then
			return spec
		end
	end
	return nil
end

local core_specs = bundles.resolve_plugins({ "core" }, {}, {})
local guess_indent = assert(find_repo(core_specs, "NMAC427/guess-indent.nvim"), "guess-indent spec should exist")
assert(type(guess_indent.opts) == "table", "guess-indent should be configured explicitly")
assert(guess_indent.opts.auto_cmd == false, "guess-indent should not run its own autocmds")
assert(guess_indent.opts.override_editorconfig == false, "guess-indent should not override editorconfig")

local indent = require("user.indent")

vim.bo.expandtab = true
vim.bo.tabstop = 4
vim.bo.shiftwidth = 4
vim.bo.softtabstop = -1
vim.bo.indentexpr = "GetTypescriptIndent()"
vim.bo.filetype = "typescript"
vim.b.editorconfig = { indent_style = "space", indent_size = "2" }

local info = indent.inspect(0)
assert(info.source == "editorconfig", "editorconfig should be reported as the indent source")
assert(info.shiftwidth == 4, "inspect should return current buffer-local options")

vim.b.editorconfig = nil
vim.b.skyline_indent_source = "guess-indent"
info = indent.inspect(0)
assert(info.source == "guess-indent", "guess-indent fallback should be reported when editorconfig is absent")

vim.b.skyline_indent_source = nil
info = indent.inspect(0)
assert(info.source == "defaults", "defaults should be reported when no other indent source is active")

local notifications = {}
local original_notify = vim.notify
vim.notify = function(msg, level, opts)
	notifications[#notifications + 1] = { msg = msg, level = level, opts = opts }
end

indent.setup()
assert(vim.fn.exists(":SkylineIndentInfo") == 2, "SkylineIndentInfo command should be registered")
vim.cmd("SkylineIndentInfo")
assert(#notifications > 0, "SkylineIndentInfo should emit a notification")
assert(notifications[#notifications].msg:match("shiftwidth"), "indent info should include current indent settings")

vim.notify = original_notify
