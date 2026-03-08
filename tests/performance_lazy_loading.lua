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

local specs = bundles.resolve_plugins({ "core", "ui", "search", "tree", "git", "syntax" }, {}, {})

local auto_session = assert(find_repo(specs, "rmagatti/auto-session"), "auto-session spec should exist")
assert(auto_session.lazy == false, "auto-session should load at startup so sessions can restore on VimEnter")
assert(auto_session.opts.auto_restore == true, "auto-session should restore sessions on startup")
assert(auto_session.opts.auto_save == true, "auto-session should save sessions on exit")

local telescope = assert(find_repo(specs, "nvim-telescope/telescope.nvim"), "telescope spec should exist")
assert(telescope.event ~= "VimEnter", "telescope should not load on VimEnter")
assert(telescope.cmd or telescope.keys, "telescope should lazy-load from commands or keys")

local tree = assert(find_repo(specs, "nvim-tree/nvim-tree.lua"), "nvim-tree spec should exist")
assert(tree.cmd ~= nil, "nvim-tree should lazy-load on commands")

local gitsigns = assert(find_repo(specs, "lewis6991/gitsigns.nvim"), "gitsigns spec should exist")
assert(type(gitsigns.event) == "table", "gitsigns should lazy-load on buffer events")
assert(vim.tbl_contains(gitsigns.event, "BufReadPre"), "gitsigns should load on BufReadPre")

local markdown = assert(find_repo(specs, "MeanderingProgrammer/render-markdown.nvim"), "render-markdown spec should exist")
assert(type(markdown.ft) == "table", "render-markdown should load on markdown filetypes")
assert(vim.tbl_contains(markdown.ft, "markdown"), "render-markdown should load for markdown")

package.loaded["user.lsp"] = nil
package.loaded["user.profile"] = {
	ensure = function()
		return {
			languages = { "lua", "rust" },
		}
	end,
}

local mason_setup
package.loaded["mason-tool-installer"] = {
	setup = function(opts)
		mason_setup = opts
	end,
}

package.loaded["blink.cmp"] = {
	get_lsp_capabilities = function()
		return { textDocument = { completion = true } }
	end,
}

local enabled_servers
local original_lsp = vim.lsp
vim.lsp = {
	config = {},
	enable = function(servers)
		enabled_servers = servers
	end,
}

require("user.lsp")

assert(vim.lsp.config.lua_ls ~= nil, "selected lua server should be registered")
assert(vim.lsp.config.rust_analyzer ~= nil, "selected rust server should be registered")
assert(vim.lsp.config.pyright == nil, "unselected python server should not be registered")
assert(vim.tbl_contains(enabled_servers, "lua_ls"), "selected servers should be enabled")
assert(vim.tbl_contains(enabled_servers, "rust_analyzer"), "selected servers should be enabled")
assert(not vim.tbl_contains(enabled_servers, "pyright"), "unselected servers should not be enabled")
assert(vim.tbl_contains(mason_setup.ensure_installed, "lua_ls"), "selected language packages should still install")
assert(vim.tbl_contains(mason_setup.ensure_installed, "rust-analyzer"), "selected language packages should still install")

vim.lsp = original_lsp
