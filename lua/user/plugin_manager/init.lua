---@class SkylinePluginManager
local M = {}

local registry_mod = require("user.plugin_manager.registry")
local loader = require("user.plugin_manager.loader")
local status = require("user.plugin_manager.status")

---@class SkylinePluginSpec
---@field [1] string Repo (e.g. "owner/repo") or full git URL.
---@field name? string Override the derived plugin name.
---@field src? string Alternative to [1].
---@field main? string Override the Lua module name for opts/config.
---@field version? string|boolean Semver constraint or pinned tag.
---@field priority? integer Higher loads earlier at startup.
---@field lazy? boolean true keeps the plugin off the startup path.
---@field event? string|string[]|table Lazy-load triggers by event.
---@field cmd? string|string[] Lazy-load triggers by command.
---@field ft? string|string[] Lazy-load triggers by filetype.
---@field keys? string|table[] Lazy-load triggers by key mapping.
---@field opts? table|fun(spec):table Plugin options table (or builder).
---@field config? true|fun(spec, opts) Custom setup (true = auto-setup).
---@field build? string|fun(spec) Run after install/update.
---@field dependencies? SkylinePluginSpec|SkylinePluginSpec[]
---@field cond? boolean|fun():boolean Skip spec when false.
---@field enabled? boolean|fun():boolean Skip spec when false.

---@class SkylinePluginStatusRow
---@field name string
---@field state "loaded"|"pending"|"error"
---@field errors string[]

local state = {
	registry = registry_mod.Registry.new(),
	native_active = false,
	loaded = {},
	loading = {},
	errors = {},
}

local function reset_state()
	state.registry = registry_mod.Registry.new()
	state.loaded = {}
	state.loading = {}
	state.errors = {}
end

---Whether Neovim provides a usable native vim.pack API (Nvim 0.12+).
---@return boolean
function M.native_supported()
	if vim.env.SKYLINE_PLUGIN_MANAGER == "lazy" then
		return false
	end
	return vim.fn.has("nvim-0.12") == 1 and type(vim.pack) == "table" and type(vim.pack.add) == "function"
end

---@return boolean
function M.is_native_active()
	return state.native_active
end

---Force-load a registered plugin by name. No-op when already loaded.
---@param name string
---@return boolean ok
function M.load(name)
	return loader.load(state, name)
end

---@param specs SkylinePluginSpec[]
---@return "pack"
function M.setup_pack(specs)
	reset_state()
	for _, spec in ipairs(specs) do
		state.registry:add(spec)
	end

	state.native_active = true
	vim.g.skyline_plugin_manager = "pack"
	loader.create_build_hooks(state)
	vim.pack.add(state.registry:pack_specs(), { confirm = false, load = false })
	loader.create_lazy_loaders(state)
	loader.load_startup(state)
	return "pack"
end

---@param specs SkylinePluginSpec[]
---@return "lazy"
function M.setup_lazy(specs)
	state.native_active = false
	vim.g.skyline_plugin_manager = "lazy"

	local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
	if not (vim.uv or vim.loop).fs_stat(lazypath) then
		vim.fn.system({
			"git",
			"clone",
			"--filter=blob:none",
			"--branch=stable",
			"https://github.com/folke/lazy.nvim.git",
			lazypath,
		})
	end
	vim.opt.rtp:prepend(lazypath)

	require("lazy").setup(specs, {
		ui = { border = "rounded" },
	})
	return "lazy"
end

---Dispatch to setup_pack on Nvim 0.12+ or setup_lazy as a fallback.
---@param specs SkylinePluginSpec[]
---@return "pack"|"lazy"
function M.setup(specs)
	if M.native_supported() then
		return M.setup_pack(specs)
	end
	return M.setup_lazy(specs)
end

---@return SkylinePluginStatusRow[]
function M.status()
	return status.rows(state)
end

status.register_command(state)

M._main_module = registry_mod.main_module

return M
