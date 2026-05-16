local M = {}

local github_prefix = "https://github.com/"
local native_active = false
local specs_by_name = {}
local ordered_names = {}
local loaded = {}
local loading = {}
local errors_by_name = {}

local function record_error(name, message)
	if not name then
		return
	end
	errors_by_name[name] = errors_by_name[name] or {}
	table.insert(errors_by_name[name], message)
end

local function notify(message, level)
	vim.notify(message, level or vim.log.levels.WARN, { title = "Skyline Pack" })
end

local function as_list(value)
	if value == nil then
		return {}
	end
	if type(value) == "string" then
		return { value }
	end
	if type(value) ~= "table" then
		return {}
	end
	local islist = vim.islist or vim.tbl_islist
	if value[1] ~= nil or islist(value) then
		return value
	end
	return { value }
end

local function repo_from_spec(spec)
	if type(spec) == "string" then
		return spec
	end
	if type(spec) == "table" then
		return spec[1] or spec.src
	end
	return nil
end

local function name_from_repo(repo)
	local name = repo:match("([^/]+)$") or repo
	name = name:gsub("%.git$", "")
	return name
end

local function spec_name(spec)
	if type(spec) == "table" and spec.name then
		return spec.name
	end
	local repo = repo_from_spec(spec)
	return repo and name_from_repo(repo) or nil
end

local function github_src(repo)
	if repo:match("^https?://") or repo:match("^git@") or repo:match("^[%w._-]+:") then
		return repo
	end
	return github_prefix .. repo .. ".git"
end

local function call_predicate(value, default)
	if value == nil then
		return default
	end
	if type(value) == "function" then
		local ok, result = pcall(value)
		return ok and result ~= false
	end
	return value ~= false
end

local function enabled(spec)
	if type(spec) ~= "table" then
		return true
	end
	return call_predicate(spec.enabled, true) and call_predicate(spec.cond, true)
end

local function has_detail(spec)
	if type(spec) ~= "table" then
		return false
	end
	for key, _ in pairs(spec) do
		if key ~= 1 and key ~= "_dependencies" then
			return true
		end
	end
	return false
end

local function normalize_spec(spec)
	local repo = repo_from_spec(spec)
	local name = spec_name(spec)
	if not repo or not name then
		return nil
	end

	local normalized = type(spec) == "table" and vim.deepcopy(spec) or { spec }
	normalized[1] = repo
	normalized.name = name
	normalized._dependencies = {}
	return normalized
end

local function add_registry_spec(spec)
	if not enabled(spec) then
		return nil
	end

	local normalized = normalize_spec(spec)
	if not normalized then
		return nil
	end

	local name = normalized.name
	local existing = specs_by_name[name]
	if existing then
		if has_detail(normalized) then
			specs_by_name[name] = vim.tbl_deep_extend("force", existing, normalized)
		end
	else
		specs_by_name[name] = normalized
		ordered_names[#ordered_names + 1] = name
	end

	local target = specs_by_name[name]
	for _, dep in ipairs(as_list(normalized.dependencies)) do
		local dep_name = add_registry_spec(dep)
		if dep_name and not vim.tbl_contains(target._dependencies, dep_name) then
			target._dependencies[#target._dependencies + 1] = dep_name
		end
	end

	return name
end

local function reset_registry()
	specs_by_name = {}
	ordered_names = {}
	loaded = {}
	loading = {}
end

local function version_from_lazy(version)
	if type(version) ~= "string" then
		return version
	end
	if version == false then
		return nil
	end
	if vim.version and vim.version.range then
		local ok, range = pcall(vim.version.range, version)
		if ok and range then
			return range
		end
	end
	return version
end

local function pack_specs()
	local result = {}
	for _, name in ipairs(ordered_names) do
		local spec = specs_by_name[name]
		result[#result + 1] = {
			name = name,
			src = github_src(spec[1]),
			version = version_from_lazy(spec.version),
		}
	end
	return result
end

local function main_module(spec)
	if spec.main then
		return spec.main
	end

	local module = spec.name
	module = module:gsub("%.nvim$", "")
	module = module:gsub("%.lua$", "")
	module = module:gsub("^vim%-", "")
	return module
end

local function resolve_opts(spec)
	if type(spec.opts) == "function" then
		local ok, opts = pcall(spec.opts, spec)
		if ok then
			return opts
		end
		local message = ("Failed to resolve opts for %s: %s"):format(spec.name, opts)
		record_error(spec.name, message)
		notify(message)
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

local function setup_module(spec, opts)
	local module = main_module(spec)
	local ok, plugin = pcall(require, module)
	if not ok then
		local message = ("Failed to require %s for %s: %s"):format(module, spec.name, plugin)
		record_error(spec.name, message)
		notify(message)
		return
	end
	if type(plugin.setup) == "function" then
		local setup_ok, err = pcall(plugin.setup, opts or {})
		if not setup_ok then
			local message = ("Failed to set up %s: %s"):format(spec.name, err)
			record_error(spec.name, message)
			notify(message)
		end
	end
end

local function configure(spec)
	if spec._configured then
		return
	end
	spec._configured = true

	local opts = resolve_opts(spec)
	if type(spec.config) == "function" then
		local ok, err = pcall(spec.config, spec, opts)
		if not ok then
			local message = ("Failed to configure %s: %s"):format(spec.name, err)
			record_error(spec.name, message)
			notify(message)
		end
	elseif spec.config == true or opts ~= nil then
		setup_module(spec, opts)
	end
end

local function run_build(spec, path)
	local build = spec.build
	if not build then
		return
	end

	if type(build) == "function" then
		local ok, err = pcall(build, spec)
		if not ok then
			local message = ("Build hook failed for %s: %s"):format(spec.name, err)
			record_error(spec.name, message)
			notify(message)
		end
		return
	end

	if type(build) ~= "string" then
		return
	end

	if build:sub(1, 1) == ":" then
		M.load(spec.name)
		local ok, err = pcall(vim.cmd, build:sub(2))
		if not ok then
			local message = ("Build command failed for %s: %s"):format(spec.name, err)
			record_error(spec.name, message)
			notify(message)
		end
		return
	end

	local args = vim.split(build, "%s+", { trimempty = true })
	if #args == 0 then
		return
	end
	vim.system(args, { cwd = path }):wait()
end

local function create_build_hooks()
	vim.api.nvim_create_autocmd("PackChanged", {
		group = vim.api.nvim_create_augroup("SkylinePackBuild", { clear = true }),
		callback = function(event)
			if not event.data or (event.data.kind ~= "install" and event.data.kind ~= "update") then
				return
			end
			local name = event.data.spec and event.data.spec.name
			local spec = name and specs_by_name[name]
			if spec then
				run_build(spec, event.data.path)
			end
		end,
	})
end

local function has_lazy_trigger(spec)
	return spec.event ~= nil or spec.cmd ~= nil or spec.ft ~= nil or spec.keys ~= nil or spec.lazy == true
end

local function event_spec(event)
	if type(event) == "string" then
		return event, nil
	end
	if type(event) == "table" then
		return event[1], event.pattern
	end
	return nil, nil
end

local function create_event_loader(group, spec, event)
	local name = spec.name
	local autocmd_event, pattern = event_spec(event)
	if not autocmd_event then
		return
	end

	if autocmd_event == "VeryLazy" then
		autocmd_event = "User"
		pattern = "VeryLazy"
	end

	vim.api.nvim_create_autocmd(autocmd_event, {
		group = group,
		once = true,
		pattern = pattern,
		callback = function()
			M.load(name)
		end,
	})
end

local function create_cmd_loader(spec, command)
	local name = spec.name
	pcall(vim.api.nvim_del_user_command, command)
	vim.api.nvim_create_user_command(command, function(opts)
		pcall(vim.api.nvim_del_user_command, command)
		M.load(name)
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

local function create_key_loader(spec, key)
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
		M.load(spec.name)
		invoke_key_rhs(rhs)
	end, opts)
end

local function create_lazy_loaders()
	local group = vim.api.nvim_create_augroup("SkylinePackLazyLoad", { clear = true })
	for _, name in ipairs(ordered_names) do
		local spec = specs_by_name[name]
		for _, event in ipairs(as_list(spec.event)) do
			create_event_loader(group, spec, event)
		end
		for _, command in ipairs(as_list(spec.cmd)) do
			create_cmd_loader(spec, command)
		end
		for _, ft in ipairs(as_list(spec.ft)) do
			vim.api.nvim_create_autocmd("FileType", {
				group = group,
				once = true,
				pattern = ft,
				callback = function()
					M.load(name)
				end,
			})
		end
		for _, key in ipairs(as_list(spec.keys)) do
			create_key_loader(spec, key)
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

local function load_startup_specs()
	local startup = {}
	for index, name in ipairs(ordered_names) do
		local spec = specs_by_name[name]
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
		M.load(item.name)
	end
end

function M.native_supported()
	if vim.env.SKYLINE_PLUGIN_MANAGER == "lazy" then
		return false
	end
	return vim.fn.has("nvim-0.12") == 1 and type(vim.pack) == "table" and type(vim.pack.add) == "function"
end

function M.is_native_active()
	return native_active
end

function M.load(name)
	if native_active then
		local spec = specs_by_name[name]
		if not spec then
			return false
		end
		if loaded[name] then
			return true
		end
		if loading[name] then
			return false
		end

		loading[name] = true
		for _, dep in ipairs(spec._dependencies or {}) do
			M.load(dep)
		end

		clear_cmd_loaders(spec)
		local ok, err = pcall(vim.cmd.packadd, name)
		if not ok then
			local message = ("Failed to load %s: %s"):format(name, err)
			record_error(name, message)
			notify(message)
			loading[name] = nil
			return false
		end

		configure(spec)
		loaded[name] = true
		loading[name] = nil
		return true
	end

	local ok, lazy = pcall(require, "lazy")
	if ok then
		lazy.load({ plugins = { name } })
		return true
	end
	return false
end

function M.setup_pack(specs)
	reset_registry()
	for _, spec in ipairs(specs) do
		add_registry_spec(spec)
	end

	native_active = true
	vim.g.skyline_plugin_manager = "pack"
	create_build_hooks()
	vim.pack.add(pack_specs(), { confirm = false, load = false })
	create_lazy_loaders()
	load_startup_specs()
	return "pack"
end

function M.setup_lazy(specs)
	native_active = false
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

function M.setup(specs)
	if M.native_supported() then
		return M.setup_pack(specs)
	end
	return M.setup_lazy(specs)
end

function M.status()
	local rows = {}
	for _, name in ipairs(ordered_names) do
		local state = "pending"
		if errors_by_name[name] then
			state = "error"
		elseif loaded[name] then
			state = "loaded"
		end
		rows[#rows + 1] = {
			name = name,
			state = state,
			errors = errors_by_name[name] or {},
		}
	end
	return rows
end

local function open_status_buffer()
	local rows = M.status()
	local lines = { ("Skyline Pack (%s) — %d plugins"):format(vim.g.skyline_plugin_manager or "?", #rows), "" }
	local icon = { loaded = "✓", pending = "·", error = "✗" }
	for _, row in ipairs(rows) do
		lines[#lines + 1] = ("%s  %-30s  %s"):format(icon[row.state] or "?", row.name, row.state)
		for _, message in ipairs(row.errors) do
			for _, errline in ipairs(vim.split(message, "\n", { plain = true })) do
				lines[#lines + 1] = "      " .. errline
			end
		end
	end

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].modifiable = false
	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		row = math.floor((vim.o.lines - math.min(#lines + 2, 30)) / 2),
		col = math.floor((vim.o.columns - 80) / 2),
		width = 80,
		height = math.min(#lines + 2, 30),
		style = "minimal",
		border = "rounded",
		title = " SkylinePackStatus ",
	})
	vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
end

vim.api.nvim_create_user_command("SkylinePackStatus", open_status_buffer, {
	desc = "Show Skyline plugin load status and errors",
})

M._main_module = main_module

return M
