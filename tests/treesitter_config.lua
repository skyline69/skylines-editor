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

local specs = bundles.resolve_plugins({ "core", "syntax" }, {}, {})
local spec = assert(find_repo(specs, "nvim-treesitter/nvim-treesitter"), "nvim-treesitter spec should exist")

local setup_opts
local installed
package.loaded["nvim-treesitter"] = {
	setup = function(opts)
		setup_opts = opts
	end,
	install = function(languages)
		installed = languages
		return {
			wait = function() end,
		}
	end,
}

assert(type(spec.config) == "function", "nvim-treesitter should use an explicit config function for the current API")
local ok, err = pcall(spec.config, spec, spec.opts)
assert(ok, ("nvim-treesitter config should not require removed configs module: %s"):format(err))
assert(type(setup_opts) == "table", "nvim-treesitter setup should be called through the current module")
assert(
	vim.tbl_contains(installed, "lua"),
	"configured treesitter languages should be installed through the current API"
)

package.loaded["user.treesitter"] = nil
package.loaded["nvim-treesitter"] = nil
local legacy_opts
package.loaded["nvim-treesitter.configs"] = {
	setup = function(opts)
		legacy_opts = opts
	end,
}

require("user.treesitter").setup(spec.opts)
assert(legacy_opts == spec.opts, "older nvim-treesitter checkouts should still use the legacy configs module")
