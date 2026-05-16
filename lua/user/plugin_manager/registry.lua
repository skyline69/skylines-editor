local util = require("user.util")
local as_list = util.as_list

local Registry = {}
Registry.__index = Registry

local github_prefix = "https://github.com/"

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

local function describe_spec(spec)
	if type(spec) == "string" then
		return ("<%s>"):format(spec)
	end
	if type(spec) == "table" then
		return ("<%s>"):format(tostring(spec[1] or spec.src or spec.name or "?"))
	end
	return ("<%s>"):format(type(spec))
end

local function normalize_spec(spec)
	local repo = repo_from_spec(spec)
	local name = spec_name(spec)
	assert(repo, ("plugin spec %s is missing a repo (first array element or src)"):format(describe_spec(spec)))
	assert(name, ("plugin spec %s could not derive a name; pass spec.name explicitly"):format(describe_spec(spec)))

	local normalized = type(spec) == "table" and vim.deepcopy(spec) or { spec }
	normalized[1] = repo
	normalized.name = name
	normalized._dependencies = {}
	return normalized
end

local function github_src(repo)
	if repo:match("^https?://") or repo:match("^git@") or repo:match("^[%w._-]+:") then
		return repo
	end
	return github_prefix .. repo .. ".git"
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

function Registry.new()
	return setmetatable({
		by_name = {},
		order = {},
	}, Registry)
end

function Registry:add(spec)
	if not enabled(spec) then
		return nil
	end

	local normalized = normalize_spec(spec)
	local name = normalized.name
	local existing = self.by_name[name]
	if existing then
		if has_detail(normalized) then
			self.by_name[name] = vim.tbl_deep_extend("force", existing, normalized)
		end
	else
		self.by_name[name] = normalized
		self.order[#self.order + 1] = name
	end

	local target = self.by_name[name]
	for _, dep in ipairs(as_list(normalized.dependencies)) do
		local dep_name = self:add(dep)
		if dep_name and not vim.tbl_contains(target._dependencies, dep_name) then
			target._dependencies[#target._dependencies + 1] = dep_name
		end
	end

	return name
end

function Registry:get(name)
	return self.by_name[name]
end

function Registry:names()
	return self.order
end

function Registry:pack_specs()
	local result = {}
	for _, name in ipairs(self.order) do
		local spec = self.by_name[name]
		result[#result + 1] = {
			name = name,
			src = github_src(spec[1]),
			version = version_from_lazy(spec.version),
		}
	end
	return result
end

local M = {
	Registry = Registry,
	main_module = main_module,
}

return M
