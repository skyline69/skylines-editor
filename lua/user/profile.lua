local M = {}

local PROFILE_VERSION = 4

local function profile_path()
	return vim.env.SKYLINE_PROFILE_PATH or (vim.fn.stdpath("state") .. "/skyline-profile.json")
end

function M.default_minimal()
	return {
		version = PROFILE_VERSION,
		features = { "core" },
		languages = {},
		qol = require("user.qol").default_selected(),
		disabled_qol = {},
	}
end

function M.default_popular()
	return {
		version = PROFILE_VERSION,
		features = { "core", "ui", "search", "tree", "git", "syntax" },
		languages = { "lua", "python", "typescript", "go", "rust", "json", "yaml", "docker" },
		qol = { "lualine", "autoclose", "todo_comments", "trouble", "spectre", "hex", "crates" },
		disabled_qol = {},
	}
end

local function normalize(profile)
	local bundles_mod = require("user.bundles")
	local languages_mod = require("user.languages")
	local qol_mod = require("user.qol")
	local normalized = M.default_minimal()
	local seen_features = { core = true }
	local seen_languages = {}
	local seen_qol = {}
	local seen_disabled_qol = {}
	local feature_source = {}
	local default_qol = require("user.qol").default_selected()

	if type(profile) ~= "table" then
		return normalized
	end

	if type(profile.features) == "table" then
		feature_source = profile.features
	elseif type(profile.bundles) == "table" then
		feature_source = profile.bundles
	end

	for _, id in ipairs(feature_source) do
		if id ~= "core" and bundles_mod.is_valid(id) and not seen_features[id] then
			seen_features[id] = true
			normalized.features[#normalized.features + 1] = id
		end
	end

	for _, id in ipairs(profile.languages or {}) do
		if languages_mod.is_valid(id) and not seen_languages[id] then
			seen_languages[id] = true
			normalized.languages[#normalized.languages + 1] = id
		end
	end

	for _, id in ipairs(profile.disabled_qol or {}) do
		if qol_mod.is_valid(id) and not seen_disabled_qol[id] and qol_mod.is_default_enabled(id) then
			seen_disabled_qol[id] = true
			normalized.disabled_qol[#normalized.disabled_qol + 1] = id
		end
	end

	normalized.qol = {}
	for _, id in ipairs(default_qol) do
		if not seen_disabled_qol[id] then
			seen_qol[id] = true
			normalized.qol[#normalized.qol + 1] = id
		end
	end

	for _, id in ipairs(profile.qol or {}) do
		if qol_mod.is_valid(id)
			and not seen_qol[id]
			and not seen_disabled_qol[id]
			and qol_mod.is_available(id, normalized.languages, normalized.features)
		then
			seen_qol[id] = true
			normalized.qol[#normalized.qol + 1] = id
		end
	end

	return normalized
end

function M.normalize(profile)
	return normalize(profile)
end

local function write_file(path, payload)
	vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
	local fd = assert(io.open(path, "w"))
	fd:write(vim.json.encode(payload))
	fd:write("\n")
	fd:close()
end

function M.path()
	return profile_path()
end

function M.exists()
	return (vim.uv or vim.loop).fs_stat(profile_path()) ~= nil
end

function M.load()
	if not M.exists() then
		return nil
	end

	local fd = io.open(profile_path(), "r")
	if not fd then
		return nil
	end

	local ok, decoded = pcall(vim.json.decode, fd:read("*a"))
	fd:close()

	if not ok or type(decoded) ~= "table" then
		return nil
	end

	return normalize(decoded)
end

function M.save(profile)
	local normalized = M.normalize(profile)
	write_file(profile_path(), normalized)
	return normalized
end

function M.ensure(opts)
	local existing = M.load()
	if existing then
		return existing
	end

	local headless = opts and opts.headless
	if headless == nil then
		headless = #vim.api.nvim_list_uis() == 0
	end

	if headless then
		return M.save(M.default_minimal())
	end

	local minimal = M.save(M.default_minimal())
	vim.g.skyline_bootstrap_pending = true
	return minimal
end

function M.has_bundle(bundle_id)
	local profile = M.ensure()
	for _, id in ipairs(profile.features) do
		if id == bundle_id then
			return true
		end
	end
	return false
end

function M.has_language(language_id)
	local profile = M.ensure()
	for _, id in ipairs(profile.languages) do
		if id == language_id then
			return true
		end
	end
	return false
end

return M
