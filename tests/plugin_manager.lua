local cwd = vim.fn.getcwd()
vim.opt.rtp:prepend(cwd)
package.path = table.concat({
	cwd .. "/lua/?.lua",
	cwd .. "/lua/?/init.lua",
	package.path,
}, ";")

package.loaded["user.plugin_manager"] = nil
local manager = require("user.plugin_manager")

local original_pack = vim.pack
local original_has = vim.fn.has
local original_system = vim.fn.system
local original_rtp = vim.opt.rtp:get()
local original_notify = vim.notify

local added_specs
vim.pack = {
	add = function(specs, opts)
		added_specs = { specs = specs, opts = opts }
	end,
}

vim.fn.has = function(feature)
	if feature == "nvim-0.12" then
		return 1
	end
	return original_has(feature)
end

vim.notify = function() end

vim.env.SKYLINE_PLUGIN_MANAGER = "lazy"
assert(manager.native_supported() == false, "SKYLINE_PLUGIN_MANAGER=lazy should force the lazy.nvim fallback")
vim.env.SKYLINE_PLUGIN_MANAGER = nil

local specs = {
	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
	},
	{ "nvim-lualine/lualine.nvim", event = "VeryLazy", opts = {} },
}

local native = manager.setup(specs)

assert(native == "pack", "Nvim 0.12+ with vim.pack should use the native package manager")
assert(added_specs ~= nil, "native setup should register plugins with vim.pack.add")
assert(added_specs.opts.confirm == false, "native setup should not prompt during startup")
assert(added_specs.opts.load == false, "native setup should defer loading to the compatibility layer")

local by_name = {}
for _, spec in ipairs(added_specs.specs) do
	by_name[spec.name] = spec
end

assert(
	by_name["telescope.nvim"].src == "https://github.com/nvim-telescope/telescope.nvim.git",
	"GitHub shorthands should become full Git URLs"
)
assert(
	by_name["plenary.nvim"].src == "https://github.com/nvim-lua/plenary.nvim.git",
	"dependencies should be added to vim.pack"
)
assert(
	by_name["telescope-fzf-native.nvim"].src == "https://github.com/nvim-telescope/telescope-fzf-native.nvim.git",
	"nested dependency specs should be added"
)
assert(
	by_name["lualine.nvim"].src == "https://github.com/nvim-lualine/lualine.nvim.git",
	"top-level specs should be added"
)
assert(vim.g.skyline_plugin_manager == "pack", "native setup should expose the active manager")

vim.pack = nil
vim.fn.has = function(feature)
	if feature == "nvim-0.12" then
		return 0
	end
	return original_has(feature)
end

local cloned
vim.fn.system = function(args)
	cloned = args
	return ""
end

local lazy_setup
package.loaded["lazy"] = {
	setup = function(received_specs, opts)
		lazy_setup = { specs = received_specs, opts = opts }
	end,
}

local fallback = manager.setup_lazy(specs)

assert(fallback == "lazy", "fallback setup should keep using lazy.nvim")
if cloned then
	assert(cloned[1] == "git" and cloned[2] == "clone", "lazy fallback should bootstrap lazy.nvim when needed")
end
assert(lazy_setup.specs == specs, "lazy fallback should pass through existing specs unchanged")
assert(lazy_setup.opts.ui.border == "rounded", "lazy fallback should preserve the existing UI option")
assert(vim.g.skyline_plugin_manager == "lazy", "lazy setup should expose the active manager")

vim.pack = original_pack
vim.fn.has = original_has
vim.fn.system = original_system
vim.opt.rtp = original_rtp
vim.notify = original_notify
