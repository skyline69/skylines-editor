local M = {}

local web_filetypes = {
	javascript = true,
	javascriptreact = true,
	typescript = true,
	typescriptreact = true,
	json = true,
	jsonc = true,
	yaml = true,
	yml = true,
	html = true,
	css = true,
	scss = true,
	markdown = true,
	svelte = true,
}

local prettier_files = {
	".prettierrc",
	".prettierrc.json",
	".prettierrc.yml",
	".prettierrc.yaml",
	".prettierrc.json5",
	".prettierrc.js",
	".prettierrc.cjs",
	".prettierrc.mjs",
	".prettierrc.toml",
	"prettier.config.js",
	"prettier.config.cjs",
	"prettier.config.mjs",
	"prettier.config.ts",
	"prettier.config.cts",
	"prettier.config.mts",
}

local fallback_by_ft = {
	lua = { "stylua" },
	python = { "black" },
	go = { "goimports", "golines" },
	yaml = { "yamlfmt" },
	yml = { "yamlfmt" },
	json = { "jq" },
	c = { "clang-format" },
	cpp = { "clang-format" },
}

local function dirname(path)
	if not path or path == "" then
		return vim.uv.cwd()
	end
	if vim.fn.isdirectory(path) == 1 then
		return path
	end
	return vim.fs.dirname(path)
end

local function find_up(names, start_dir)
	local found = vim.fs.find(names, { upward = true, path = start_dir, stop = vim.uv.os_homedir() })
	return found[1]
end

local function read_json(path)
	local fd = io.open(path, "r")
	if not fd then
		return nil
	end
	local ok, decoded = pcall(vim.json.decode, fd:read("*a"))
	fd:close()
	if ok and type(decoded) == "table" then
		return decoded
	end
	return nil
end

local function local_executable(root, relpath)
	if not root then
		return nil
	end
	local full = vim.fs.joinpath(root, relpath)
	return vim.fn.executable(full) == 1 and full or nil
end

local function warn_missing(bufnr, info)
	local key = ("%s:%s"):format(info.project_formatter or "formatter", info.root or "")
	if vim.b[bufnr].skyline_format_warning == key then
		return
	end
	vim.b[bufnr].skyline_format_warning = key
	vim.notify(
		("Project formatter '%s' is configured at %s, but the required executable is missing. Formatting was skipped.")
			:format(info.project_formatter, info.config_path),
		vim.log.levels.WARN,
		{ title = "Skyline Format" }
	)
end

local function web_project_formatter(filename)
	local start_dir = dirname(filename)

	local biome_config = find_up({ "biome.json", "biome.jsonc" }, start_dir)
	if biome_config then
		local root = vim.fs.dirname(biome_config)
		local biome = local_executable(root, "node_modules/.bin/biome")
		if biome then
			return {
				source = "project",
				project_formatter = "biome",
				root = root,
				config_path = biome_config,
				command = biome,
				formatters = { "skyline_biome" },
				lsp_format = "never",
			}
		end
		return {
			source = "project-missing",
			project_formatter = "biome",
			root = root,
			config_path = biome_config,
			formatters = {},
			lsp_format = "never",
		}
	end

	local prettier_config = find_up(prettier_files, start_dir)
	if not prettier_config then
		local package_json = find_up({ "package.json" }, start_dir)
		if package_json then
			local package_data = read_json(package_json)
			if package_data and package_data.prettier ~= nil then
				prettier_config = package_json
			end
		end
	end

	if prettier_config then
		local root = vim.fs.dirname(prettier_config)
		local prettierd = local_executable(root, "node_modules/.bin/prettierd")
		local prettier = local_executable(root, "node_modules/.bin/prettier")
		if prettierd then
			return {
				source = "project",
				project_formatter = "prettier",
				root = root,
				config_path = prettier_config,
				command = prettierd,
				formatters = { "skyline_prettierd" },
				lsp_format = "never",
			}
		elseif prettier then
			return {
				source = "project",
				project_formatter = "prettier",
				root = root,
				config_path = prettier_config,
				command = prettier,
				formatters = { "skyline_prettier" },
				lsp_format = "never",
			}
		end
		return {
			source = "project-missing",
			project_formatter = "prettier",
			root = root,
			config_path = prettier_config,
			formatters = {},
			lsp_format = "never",
		}
	end

	local deno_config = find_up({ "deno.json", "deno.jsonc" }, start_dir)
	if deno_config then
		local root = vim.fs.dirname(deno_config)
		if vim.fn.executable("deno") == 1 then
			return {
				source = "project",
				project_formatter = "deno",
				root = root,
				config_path = deno_config,
				formatters = { "skyline_deno_fmt" },
				lsp_format = "never",
			}
		end
		return {
			source = "project-missing",
			project_formatter = "deno",
			root = root,
			config_path = deno_config,
			formatters = {},
			lsp_format = "never",
		}
	end

	return nil
end

function M.resolve(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local filetype = vim.bo[bufnr].filetype
	local filename = vim.api.nvim_buf_get_name(bufnr)

	if web_filetypes[filetype] then
		local project = web_project_formatter(filename)
		if project then
			project.filetype = filetype
			return project
		end
	end

	local fallback = fallback_by_ft[filetype]
	if fallback then
		return {
			source = "fallback",
			filetype = filetype,
			root = dirname(filename),
			formatters = vim.deepcopy(fallback),
			lsp_format = "never",
		}
	end

	return {
		source = "lsp-fallback",
		filetype = filetype,
		root = dirname(filename),
		formatters = {},
		lsp_format = "fallback",
	}
end

function M.inspect(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local info = M.resolve(bufnr)
	info.filename = vim.api.nvim_buf_get_name(bufnr)
	return info
end

function M.setup()
	if vim.fn.exists(":SkylineFormatInfo") == 0 then
		vim.api.nvim_create_user_command("SkylineFormatInfo", function()
			local info = M.inspect(0)
			local lines = {
				("source: %s"):format(info.source),
				("filetype: %s"):format(info.filetype ~= "" and info.filetype or "none"),
				("root: %s"):format(info.root or "none"),
				("formatters: %s"):format(#info.formatters > 0 and table.concat(info.formatters, ", ") or "none"),
				("lsp_format: %s"):format(info.lsp_format),
			}
			if info.project_formatter then
				lines[#lines + 1] = ("project_formatter: %s"):format(info.project_formatter)
			end
			if info.config_path then
				lines[#lines + 1] = ("config_path: %s"):format(info.config_path)
			end
			vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Skyline Format Info" })
		end, { desc = "Show active formatter resolution for the current buffer" })
	end
end

local function formatter_for(bufnr)
	local info = M.resolve(bufnr)
	if info.source == "project-missing" then
		return nil, info
	end
	return info.formatters, info
end

function M.format(opts)
	local ok, conform = pcall(require, "conform")
	if not ok then
		vim.notify("Conform not installed", vim.log.levels.WARN)
		return
	end

	opts = opts or {}
	local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
	local formatters, info = formatter_for(bufnr)
	if not formatters then
		warn_missing(bufnr, info)
		return
	end

	local merged = vim.tbl_extend("force", {
		bufnr = bufnr,
		formatters = #formatters > 0 and formatters or nil,
		lsp_format = info.lsp_format,
	}, opts)

	return conform.format(merged)
end

function M.format_on_save_opts(bufnr)
	local formatters, info = formatter_for(bufnr)
	if not formatters then
		warn_missing(bufnr, info)
		return nil
	end

	return {
		timeout_ms = 2000,
		formatters = #formatters > 0 and formatters or nil,
		lsp_format = info.lsp_format,
	}
end

function M.opts()
	local util = require("conform.util")
	local function root_from_info(ctx)
		return M.resolve(ctx.buf).root
	end

	local function by_ft(bufnr)
		local formatters = M.resolve(bufnr).formatters
		return #formatters > 0 and formatters or {}
	end

	return {
		formatters = {
			skyline_biome = {
				inherit = "biome",
				command = function(_, ctx)
					return M.resolve(ctx.buf).command
				end,
				cwd = root_from_info,
				require_cwd = true,
			},
			skyline_prettierd = {
				inherit = "prettierd",
				command = function(_, ctx)
					return M.resolve(ctx.buf).command
				end,
				cwd = root_from_info,
				require_cwd = true,
			},
			skyline_prettier = {
				inherit = "prettier",
				command = function(_, ctx)
					return M.resolve(ctx.buf).command
				end,
				cwd = root_from_info,
				require_cwd = true,
			},
			skyline_deno_fmt = {
				inherit = "deno_fmt",
				cwd = root_from_info,
				require_cwd = true,
				condition = function(_, ctx)
					return M.resolve(ctx.buf).source == "project"
				end,
			},
		},
		formatters_by_ft = {
			javascript = by_ft,
			javascriptreact = by_ft,
			typescript = by_ft,
			typescriptreact = by_ft,
			json = by_ft,
			jsonc = by_ft,
			yaml = by_ft,
			yml = by_ft,
			html = by_ft,
			css = by_ft,
			scss = by_ft,
			markdown = by_ft,
			svelte = by_ft,
			lua = by_ft,
			python = by_ft,
			go = by_ft,
			c = by_ft,
			cpp = by_ft,
		},
		format_on_save = function(bufnr)
			return M.format_on_save_opts(bufnr)
		end,
	}
end

return M
