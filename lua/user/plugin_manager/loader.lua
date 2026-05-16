local util = require("user.util")
local registry_mod = require("user.plugin_manager.registry")
local main_module = registry_mod.main_module
local as_list = util.as_list

local M = {}

local function notify(message, level)
	vim.notify(message, level or vim.log.levels.WARN, { title = "Skyline Pack" })
end

local function record_error(state, name, message)
	state.errors[name] = state.errors[name] or {}
	table.insert(state.errors[name], message)
end

local function report_error(state, name, fmt, ...)
	local message = fmt:format(...)
	if name then
		record_error(state, name, message)
	end
	notify(message)
end

local function resolve_opts(state, spec)
	if type(spec.opts) == "function" then
		local ok, opts = pcall(spec.opts, spec)
		if ok then
			return opts
		end
		report_error(state, spec.name, "Failed to resolve opts for %s: %s", spec.name, opts)
		return nil
	end
	if type(spec.opts) == "table" then
		return vim.deepcopy(spec.opts)
	end
	if spec.opts == true then
		return {}
	end
	return nil
end

local function setup_module(state, spec, opts)
	local module = main_module(spec)
	local plugin, err = util.safe_require(module)
	if not plugin then
		report_error(state, spec.name, "Failed to require %s for %s: %s", module, spec.name, err)
		return
	end
	if type(plugin.setup) == "function" then
		local ok, setup_err = pcall(plugin.setup, opts or {})
		if not ok then
			report_error(state, spec.name, "Failed to set up %s: %s", spec.name, setup_err)
		end
	end
end

local function configure(state, spec)
	if spec._configured then
		return
	end
	spec._configured = true

	local opts = resolve_opts(state, spec)
	if type(spec.config) == "function" then
		local ok, err = pcall(spec.config, spec, opts)
		if not ok then
			report_error(state, spec.name, "Failed to configure %s: %s", spec.name, err)
		end
	elseif spec.config == true or opts ~= nil then
		setup_module(state, spec, opts)
	end
end

local function run_build(state, spec, path)
	local build = spec.build
	if not build then
		return
	end

	if type(build) == "function" then
		local ok, err = pcall(build, spec)
		if not ok then
			report_error(state, spec.name, "Build hook failed for %s: %s", spec.name, err)
		end
		return
	end

	if type(build) ~= "string" then
		return
	end

	if build:sub(1, 1) == ":" then
		M.load(state, spec.name)
		local ok, err = pcall(vim.cmd, build:sub(2))
		if not ok then
			report_error(state, spec.name, "Build command failed for %s: %s", spec.name, err)
		end
		return
	end

	local args = vim.split(build, "%s+", { trimempty = true })
	if #args == 0 then
		return
	end
	vim.system(args, { cwd = path }):wait()
end

local function event_spec(event)
	if type(event) == "string" then
		return { event = event }
	end
	if type(event) == "table" then
		return { event = event[1], pattern = event.pattern }
	end
	return {}
end

local function create_event_loader(state, group, spec, event)
	local trigger = event_spec(event)
	if not trigger.event then
		return
	end

	if trigger.event == "VeryLazy" then
		trigger.event = "User"
		trigger.pattern = "VeryLazy"
	end

	local name = spec.name
	vim.api.nvim_create_autocmd(trigger.event, {
		group = group,
		once = true,
		pattern = trigger.pattern,
		callback = function()
			M.load(state, name)
		end,
	})
end

local function create_cmd_loader(state, spec, command)
	local name = spec.name
	pcall(vim.api.nvim_del_user_command, command)
	vim.api.nvim_create_user_command(command, function(opts)
		pcall(vim.api.nvim_del_user_command, command)
		M.load(state, name)
		local cmd = {
			cmd = command,
			args = opts.args,
			bang = opts.bang,
		}
		if opts.range and opts.range > 0 then
			cmd.range = { opts.line1, opts.line2 }
		end
		vim.api.nvim_cmd(cmd, {})
	end, { nargs = "*", bang = true, range = true })
end

local function clear_cmd_loaders(spec)
	for _, command in ipairs(as_list(spec.cmd)) do
		pcall(vim.api.nvim_del_user_command, command)
	end
end

local function invoke_key_rhs(rhs)
	if type(rhs) == "function" then
		rhs()
	elseif type(rhs) == "string" then
		local keys = vim.api.nvim_replace_termcodes(rhs, true, false, true)
		vim.api.nvim_feedkeys(keys, "m", false)
	end
end

local function create_key_loader(state, spec, key)
	local lhs = type(key) == "string" and key or key[1]
	if not lhs then
		return
	end

	local rhs = type(key) == "table" and key[2] or nil
	local mode = type(key) == "table" and key.mode or "n"
	local opts = {
		desc = type(key) == "table" and key.desc or nil,
		silent = type(key) ~= "table" or key.silent ~= false,
	}

	vim.keymap.set(mode, lhs, function()
		M.load(state, spec.name)
		invoke_key_rhs(rhs)
	end, opts)
end

local function has_lazy_trigger(spec)
	return spec.event ~= nil or spec.cmd ~= nil or spec.ft ~= nil or spec.keys ~= nil or spec.lazy == true
end

function M.create_build_hooks(state)
	vim.api.nvim_create_autocmd("PackChanged", {
		group = vim.api.nvim_create_augroup("SkylinePackBuild", { clear = true }),
		callback = function(event)
			if not event.data or (event.data.kind ~= "install" and event.data.kind ~= "update") then
				return
			end
			local name = event.data.spec and event.data.spec.name
			local spec = name and state.registry:get(name)
			if spec then
				run_build(state, spec, event.data.path)
			end
		end,
	})
end

function M.create_lazy_loaders(state)
	local group = vim.api.nvim_create_augroup("SkylinePackLazyLoad", { clear = true })
	for _, name in ipairs(state.registry:names()) do
		local spec = state.registry:get(name)
		for _, event in ipairs(as_list(spec.event)) do
			create_event_loader(state, group, spec, event)
		end
		for _, command in ipairs(as_list(spec.cmd)) do
			create_cmd_loader(state, spec, command)
		end
		for _, ft in ipairs(as_list(spec.ft)) do
			vim.api.nvim_create_autocmd("FileType", {
				group = group,
				once = true,
				pattern = ft,
				callback = function()
					M.load(state, name)
				end,
			})
		end
		for _, key in ipairs(as_list(spec.keys)) do
			create_key_loader(state, spec, key)
		end
	end

	vim.api.nvim_create_autocmd("VimEnter", {
		group = group,
		once = true,
		callback = function()
			vim.schedule(function()
				vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy", modeline = false })
			end)
		end,
	})
end

function M.load_startup(state)
	local startup = {}
	for index, name in ipairs(state.registry:names()) do
		local spec = state.registry:get(name)
		if spec.lazy == false or not has_lazy_trigger(spec) then
			startup[#startup + 1] = { name = name, index = index, priority = spec.priority or 0 }
		end
	end

	table.sort(startup, function(a, b)
		if a.priority == b.priority then
			return a.index < b.index
		end
		return a.priority > b.priority
	end)

	for _, item in ipairs(startup) do
		M.load(state, item.name)
	end
end

function M.load(state, name)
	if state.native_active then
		local spec = state.registry:get(name)
		if not spec then
			return false
		end
		if state.loaded[name] then
			return true
		end
		if state.loading[name] then
			return false
		end

		state.loading[name] = true
		for _, dep in ipairs(spec._dependencies or {}) do
			local dep_spec = state.registry:get(dep)
			if dep_spec and not has_lazy_trigger(dep_spec) then
				M.load(state, dep)
			end
		end

		clear_cmd_loaders(spec)
		local ok, err = pcall(vim.cmd.packadd, name)
		if not ok then
			report_error(state, name, "Failed to load %s: %s", name, err)
			state.loading[name] = nil
			return false
		end

		configure(state, spec)
		state.loaded[name] = true
		state.loading[name] = nil
		return true
	end

	local lazy, lazy_err = util.safe_require("lazy")
	if lazy then
		lazy.load({ plugins = { name } })
		return true
	end
	notify("lazy.nvim not available: " .. tostring(lazy_err))
	return false
end

return M
