---@class SkylineLanguages
local M = {}

---@class SkylinePackageEntry
---@field name string Mason package id.
---@field label string Display label.

---@class SkylineResolvedLanguages
---@field languages string[]
---@field servers string[]
---@field mason_packages string[]
---@field required_features string[]
---@field tools string[]

---@param name string
---@param label? string
---@return SkylinePackageEntry
local function pkg(name, label)
	return { name = name, label = label or name }
end

local catalog = {
	lua = {
		label = "Lua",
		description = "Neovim and Lua projects.",
		servers = { "lua_ls" },
		packages = { pkg("lua_ls"), pkg("stylua") },
	},
	python = {
		label = "Python",
		description = "Pyright with Black formatting.",
		servers = { "pyright" },
		packages = { pkg("pyright"), pkg("black") },
	},
	typescript = {
		label = "TypeScript",
		description = "TypeScript/JavaScript language support.",
		servers = { "ts_ls" },
		packages = { pkg("typescript-language-server", "ts_ls") },
	},
	go = {
		label = "Go",
		description = "Gopls, import/line formatting, and golangci-lint.",
		servers = { "gopls" },
		packages = { pkg("gopls"), pkg("goimports"), pkg("golines"), pkg("golangci-lint") },
	},
	rust = {
		label = "Rust",
		description = "Rust analyzer.",
		servers = { "rust_analyzer" },
		packages = { pkg("rust-analyzer") },
	},
	web = {
		label = "Web",
		description = "HTML, Tailwind CSS, and Svelte.",
		servers = { "html", "tailwindcss", "svelte" },
		packages = {
			pkg("html-lsp", "html"),
			pkg("tailwindcss-language-server", "tailwindcss"),
			pkg("svelte-language-server", "svelte"),
		},
	},
	docker = {
		label = "Docker",
		description = "Docker language support.",
		servers = { "dockerls" },
		packages = { pkg("dockerfile-language-server", "dockerls") },
	},
	yaml = {
		label = "YAML",
		description = "YAML language server and formatter.",
		servers = { "yamlls" },
		packages = { pkg("yaml-language-server", "yamlls"), pkg("yamlfmt") },
	},
	json = {
		label = "JSON",
		description = "JSON language support and formatting.",
		servers = { "jsonls" },
		packages = { pkg("json-lsp", "jsonls"), pkg("jq") },
	},
	elixir = {
		label = "Elixir",
		description = "Elixir tooling via elixir-tools.",
		servers = {},
		packages = {},
		extra_tools = { "elixir-tools.nvim" },
		requires_features = { "extras" },
	},
	zig = {
		label = "Zig",
		description = "ZLS language support.",
		servers = { "zls" },
		packages = { pkg("zls") },
	},
	c_cpp = {
		label = "C / C++",
		description = "Clangd and clang-format.",
		servers = { "clangd" },
		packages = { pkg("clangd"), pkg("clang-format") },
	},
	csharp = {
		label = "C#",
		description = "C# LSP plus CSharpier.",
		servers = { "csharp_ls" },
		packages = { pkg("csharp-ls", "csharp_ls"), pkg("csharpier") },
	},
}

local function item_mason_packages(item)
	local out = {}
	for _, p in ipairs(item.packages or {}) do
		out[#out + 1] = p.name
	end
	return out
end

local function item_tool_labels(item)
	local out = {}
	for _, p in ipairs(item.packages or {}) do
		out[#out + 1] = p.label
	end
	for _, extra in ipairs(item.extra_tools or {}) do
		out[#out + 1] = extra
	end
	return out
end

local ordered_ids = {
	"lua",
	"python",
	"typescript",
	"go",
	"rust",
	"web",
	"docker",
	"yaml",
	"json",
	"elixir",
	"zig",
	"c_cpp",
	"csharp",
}

local function uniq_extend(target, seen, values)
	for _, value in ipairs(values or {}) do
		if not seen[value] then
			seen[value] = true
			target[#target + 1] = value
		end
	end
end

local api = require("user.catalog").from(catalog, ordered_ids, function(id, item)
	return {
		id = id,
		label = item.label,
		description = item.description,
		tools = item_tool_labels(item),
	}
end)

M.get_all = api.get_all
M.is_valid = api.is_valid

---@param selected_ids string[]
---@return SkylineResolvedLanguages
function M.resolve(selected_ids)
	local normalized = {}
	local seen_ids = {}
	local servers = {}
	local mason_packages = {}
	local required_features = {}
	local tool_labels = {}
	local seen_servers = {}
	local seen_packages = {}
	local seen_features = {}
	local seen_tools = {}

	for _, id in ipairs(selected_ids or {}) do
		local item = catalog[id]
		if item and not seen_ids[id] then
			seen_ids[id] = true
			normalized[#normalized + 1] = id
			uniq_extend(servers, seen_servers, item.servers or {})
			uniq_extend(mason_packages, seen_packages, item_mason_packages(item))
			uniq_extend(required_features, seen_features, item.requires_features or {})
			uniq_extend(tool_labels, seen_tools, item_tool_labels(item))
		end
	end

	return {
		languages = normalized,
		servers = servers,
		mason_packages = mason_packages,
		required_features = required_features,
		tools = tool_labels,
	}
end

return M
