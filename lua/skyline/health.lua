local M = {}

local function start(name)
	(vim.health.start or vim.health.report_start)(name)
end

local function ok(message)
	(vim.health.ok or vim.health.report_ok)(message)
end

local function warn(message, advice)
	(vim.health.warn or vim.health.report_warn)(message, advice)
end

local function err(message, advice)
	(vim.health.error or vim.health.report_error)(message, advice)
end

local function info(message)
	(vim.health.info or vim.health.report_info)(message)
end

local function check_profile()
	start("profile")
	local profile_ok, profile = pcall(require, "user.profile")
	if not profile_ok then
		err("user.profile module failed to load: " .. tostring(profile))
		return
	end
	local loaded = profile.load and profile.load() or nil
	if not loaded then
		warn("no saved profile found", { "Run :SkylineSetup to choose bundles and languages." })
		return
	end
	ok(
		("profile loaded — bundles=%d languages=%d qol=%d"):format(
			#(loaded.features or {}),
			#(loaded.languages or {}),
			#(loaded.qol or {})
		)
	)
end

local function check_manager()
	start("plugin manager")
	local mgr_ok, mgr = pcall(require, "user.plugin_manager")
	if not mgr_ok then
		err("user.plugin_manager failed to load: " .. tostring(mgr))
		return
	end
	local active = vim.g.skyline_plugin_manager
	if active == "pack" then
		ok("vim.pack native manager active")
	elseif active == "lazy" then
		ok("lazy.nvim fallback active")
	else
		warn("no plugin manager registered yet")
	end

	if mgr.native_supported() then
		info("vim.pack is supported on this Neovim")
	else
		info("vim.pack is not supported — lazy.nvim fallback used")
	end

	local lockfile = vim.fn.stdpath("config") .. "/nvim-pack-lock.json"
	if (vim.uv or vim.loop).fs_stat(lockfile) then
		ok("lockfile present: " .. lockfile)
	else
		warn("lockfile missing: " .. lockfile)
	end

	if type(mgr.status) == "function" then
		local rows = mgr.status()
		local failed = {}
		for _, row in ipairs(rows) do
			if row.state == "error" then
				failed[#failed + 1] = row.name
			end
		end
		if #failed == 0 then
			ok(("%d plugins registered, no load errors"):format(#rows))
		else
			err(("%d plugins failed: %s"):format(#failed, table.concat(failed, ", ")), {
				"Run :SkylinePackStatus for details.",
			})
		end
	end
end

local function check_treesitter()
	start("treesitter")
	if not vim.tbl_contains(vim.g.skyline_active_bundles or {}, "syntax") then
		info("syntax bundle not active — skipping")
		return
	end
	if vim.fn.executable("tree-sitter") == 1 then
		ok("tree-sitter CLI found on PATH")
	else
		local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/tree-sitter"
		if (vim.uv or vim.loop).fs_stat(mason_bin) then
			ok("tree-sitter CLI installed via mason at " .. mason_bin)
		else
			warn("tree-sitter CLI missing", {
				"Run :MasonInstall tree-sitter or install via system package manager.",
			})
		end
	end
end

local function check_mason()
	start("mason tools")
	local registry_ok, registry = pcall(require, "mason-registry")
	if not registry_ok then
		warn("mason-registry not available")
		return
	end
	local languages_ok, languages = pcall(require, "user.languages")
	local profile_ok, profile = pcall(require, "user.profile")
	if not languages_ok or not profile_ok then
		return
	end
	local saved = profile.load and profile.load()
	if not saved then
		return
	end
	local resolved = languages.resolve(saved.languages)
	local missing = {}
	for _, name in ipairs(resolved.mason_packages or {}) do
		local pkg_ok, pkg = pcall(registry.get_package, name)
		if pkg_ok and pkg and not pkg:is_installed() then
			missing[#missing + 1] = name
		end
	end
	if #missing == 0 then
		ok("all required mason packages installed")
	else
		warn(("%d mason packages missing: %s"):format(#missing, table.concat(missing, ", ")), {
			"They will install on next startup, or run :MasonToolsInstall.",
		})
	end
end

function M.check()
	check_profile()
	check_manager()
	check_treesitter()
	check_mason()
end

return M
