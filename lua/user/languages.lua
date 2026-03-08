local M = {}

local catalog = {
	lua = {
		label = "Lua",
		description = "Neovim and Lua projects.",
		servers = { "lua_ls" },
		mason_packages = { "lua_ls", "stylua" },
		tools = { "lua_ls", "stylua" },
	},
	python = {
		label = "Python",
		description = "Pyright with Black formatting.",
		servers = { "pyright" },
		mason_packages = { "pyright", "black" },
		tools = { "pyright", "black" },
	},
	typescript = {
		label = "TypeScript",
		description = "TypeScript/JavaScript language support.",
		servers = { "ts_ls" },
		mason_packages = { "typescript-language-server" },
		tools = { "ts_ls" },
	},
	go = {
		label = "Go",
		description = "Gopls plus import and line formatting.",
		servers = { "gopls" },
		mason_packages = { "gopls", "goimports", "golines" },
		tools = { "gopls", "goimports", "golines" },
	},
	rust = {
		label = "Rust",
		description = "Rust analyzer.",
		servers = { "rust_analyzer" },
		mason_packages = { "rust-analyzer" },
		tools = { "rust-analyzer" },
	},
	web = {
		label = "Web",
		description = "HTML, Tailwind CSS, and Svelte.",
		servers = { "html", "tailwindcss", "svelte" },
		mason_packages = { "html-lsp", "tailwindcss-language-server", "svelte-language-server" },
		tools = { "html", "tailwindcss", "svelte" },
	},
	docker = {
		label = "Docker",
		description = "Docker language support.",
		servers = { "dockerls" },
		mason_packages = { "dockerfile-language-server" },
		tools = { "dockerls" },
	},
	yaml = {
		label = "YAML",
		description = "YAML language server and formatter.",
		servers = { "yamlls" },
		mason_packages = { "yaml-language-server", "yamlfmt" },
		tools = { "yamlls", "yamlfmt" },
	},
	json = {
		label = "JSON",
		description = "JSON language support and formatting.",
		servers = { "jsonls" },
		mason_packages = { "json-lsp", "jq" },
		tools = { "jsonls", "jq" },
	},
	elixir = {
		label = "Elixir",
		description = "Elixir tooling via elixir-tools.",
		servers = {},
		mason_packages = {},
		tools = { "elixir-tools.nvim" },
		requires_features = { "extras" },
	},
	zig = {
		label = "Zig",
		description = "ZLS language support.",
		servers = { "zls" },
		mason_packages = { "zls" },
		tools = { "zls" },
	},
	c_cpp = {
		label = "C / C++",
		description = "Clangd and clang-format.",
		servers = { "clangd" },
		mason_packages = { "clangd", "clang-format" },
		tools = { "clangd", "clang-format" },
	},
	csharp = {
		label = "C#",
		description = "C# LSP plus CSharpier.",
		servers = { "csharp_ls" },
		mason_packages = { "csharp-ls", "csharpier" },
		tools = { "csharp_ls", "csharpier" },
	},
}

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

function M.get_all()
	local result = {}
	for _, id in ipairs(ordered_ids) do
		local item = catalog[id]
		result[#result + 1] = {
			id = id,
			label = item.label,
			description = item.description,
			tools = item.tools,
		}
	end
	return result
end

function M.is_valid(id)
	return catalog[id] ~= nil
end

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
			uniq_extend(mason_packages, seen_packages, item.mason_packages or {})
			uniq_extend(required_features, seen_features, item.requires_features or {})
			uniq_extend(tool_labels, seen_tools, item.tools or {})
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
