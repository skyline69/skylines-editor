local M = {}

local colors = {
	bg = "#10141b",
	panel = "#151b24",
	panel_alt = "#1d2531",
	fg = "#f2f4f8",
	muted = "#8a8f98",
	blue = "#78a9ff",
	cyan = "#3ddbd9",
	green = "#42be65",
	yellow = "#f1c21b",
	orange = "#ff832b",
	red = "#ee5396",
	purple = "#be95ff",
}

local root_markers = {
	".git",
	"package.json",
	"Cargo.toml",
	"go.mod",
	"pyproject.toml",
	"deno.json",
	"deno.jsonc",
	"stylua.toml",
	"Makefile",
}

local mode_names = {
	n = "NORMAL",
	no = "OP",
	nov = "OP",
	noV = "OP",
	["no\22"] = "OP",
	niI = "NORMAL",
	niR = "NORMAL",
	niV = "NORMAL",
	nt = "NORMAL",
	v = "VISUAL",
	vs = "VISUAL",
	V = "V-LINE",
	Vs = "V-LINE",
	["\22"] = "V-BLOCK",
	["\22s"] = "V-BLOCK",
	s = "SELECT",
	S = "S-LINE",
	["\19"] = "S-BLOCK",
	i = "INSERT",
	ic = "INSERT",
	ix = "INSERT",
	R = "REPLACE",
	Rc = "REPLACE",
	Rx = "REPLACE",
	Rv = "V-REPLACE",
	c = "COMMAND",
	cv = "COMMAND",
	ce = "COMMAND",
	r = "PROMPT",
	rm = "MORE",
	["r?"] = "CONFIRM",
	["!"] = "SHELL",
	t = "TERMINAL",
}

local function current_buf(bufnr)
	return bufnr or vim.api.nvim_get_current_buf()
end

local function current_file(bufnr)
	return vim.api.nvim_buf_get_name(current_buf(bufnr))
end

local function dirname(path)
	if path == "" then
		return vim.uv.cwd()
	end
	return vim.fs.dirname(path)
end

function M.project_root_path(bufnr)
	local file = current_file(bufnr)
	local root = vim.fs.root(dirname(file), root_markers)
	return root or vim.uv.cwd()
end

function M.project_root(bufnr)
	local root = M.project_root_path(bufnr)
	return root and vim.fs.basename(root) or vim.fs.basename(vim.uv.cwd())
end

function M.file_path(bufnr)
	local file = current_file(bufnr)
	if file == "" then
		return "[No Name]"
	end

	local root = M.project_root_path(bufnr)
	if root and vim.startswith(file, root .. "/") then
		return file:sub(#root + 2)
	end

	return vim.fn.fnamemodify(file, ":~:.")
end

function M.mode_label()
	return (" %s "):format(mode_names[vim.fn.mode()] or "NORMAL")
end

function M.file_context()
	local bufnr = current_buf()
	local path = M.file_path(bufnr)
	local marks = {}

	if vim.bo[bufnr].modified then
		table.insert(marks, "+")
	end
	if vim.bo[bufnr].readonly then
		table.insert(marks, "ro")
	end

	if #marks == 0 then
		return path
	end

	return ("%s [%s]"):format(path, table.concat(marks, ","))
end

function M.package_status()
	if vim.bo.filetype ~= "json" or vim.fn.expand("%:t") ~= "package.json" then
		return ""
	end

	local ok, package_info = pcall(require, "package-info")
	if not ok or type(package_info.get_status) ~= "function" then
		return ""
	end

	local status = package_info.get_status()
	if status == nil then
		return ""
	end

	return status
end

function M.formatter_status()
	local ok, formatting = pcall(require, "user.formatting")
	if not ok then
		return ""
	end

	local resolved = formatting.resolve(current_buf())
	if not resolved then
		return ""
	end

	if resolved.project_formatter then
		return "fmt:" .. resolved.project_formatter
	end
	if resolved.formatters and resolved.formatters[1] then
		return "fmt:" .. resolved.formatters[1]
	end

	return ""
end

function M.lsp_status()
	local clients = vim.lsp.get_clients({ bufnr = current_buf() })
	if #clients == 0 then
		return ""
	end

	local names = {}
	for _, client in ipairs(clients) do
		table.insert(names, client.name)
	end

	return "lsp:" .. table.concat(names, ",")
end

function M.theme()
	return {
		normal = {
			a = { fg = colors.bg, bg = colors.blue, gui = "bold" },
			b = { fg = colors.fg, bg = colors.panel_alt },
			c = { fg = colors.fg, bg = colors.panel },
			x = { fg = colors.muted, bg = colors.panel },
			y = { fg = colors.fg, bg = colors.panel_alt },
			z = { fg = colors.bg, bg = colors.cyan, gui = "bold" },
		},
		insert = {
			a = { fg = colors.bg, bg = colors.green, gui = "bold" },
			b = { fg = colors.fg, bg = colors.panel_alt },
			c = { fg = colors.fg, bg = colors.panel },
			x = { fg = colors.muted, bg = colors.panel },
			y = { fg = colors.fg, bg = colors.panel_alt },
			z = { fg = colors.bg, bg = colors.cyan, gui = "bold" },
		},
		visual = {
			a = { fg = colors.bg, bg = colors.purple, gui = "bold" },
			b = { fg = colors.fg, bg = colors.panel_alt },
			c = { fg = colors.fg, bg = colors.panel },
			x = { fg = colors.muted, bg = colors.panel },
			y = { fg = colors.fg, bg = colors.panel_alt },
			z = { fg = colors.bg, bg = colors.cyan, gui = "bold" },
		},
		replace = {
			a = { fg = colors.bg, bg = colors.orange, gui = "bold" },
			b = { fg = colors.fg, bg = colors.panel_alt },
			c = { fg = colors.fg, bg = colors.panel },
			x = { fg = colors.muted, bg = colors.panel },
			y = { fg = colors.fg, bg = colors.panel_alt },
			z = { fg = colors.bg, bg = colors.cyan, gui = "bold" },
		},
		command = {
			a = { fg = colors.bg, bg = colors.yellow, gui = "bold" },
			b = { fg = colors.fg, bg = colors.panel_alt },
			c = { fg = colors.fg, bg = colors.panel },
			x = { fg = colors.muted, bg = colors.panel },
			y = { fg = colors.fg, bg = colors.panel_alt },
			z = { fg = colors.bg, bg = colors.cyan, gui = "bold" },
		},
		inactive = {
			a = { fg = colors.muted, bg = colors.panel },
			b = { fg = colors.muted, bg = colors.panel },
			c = { fg = colors.muted, bg = colors.panel },
			x = { fg = colors.muted, bg = colors.panel },
			y = { fg = colors.muted, bg = colors.panel },
			z = { fg = colors.muted, bg = colors.panel },
		},
	}
end

function M.opts()
	return {
		options = {
			theme = M.theme(),
			globalstatus = true,
			component_separators = { left = "·", right = "·" },
			section_separators = { left = "", right = "" },
			disabled_filetypes = {
				statusline = { "alpha" },
				winbar = { "alpha", "NvimTree" },
			},
			always_divide_middle = true,
		},
		sections = {
			lualine_a = {
				{ M.mode_label, padding = 0 },
			},
			lualine_b = {
				{ M.project_root, icon = "󰉋", color = { fg = colors.blue, bg = colors.panel_alt, gui = "bold" } },
				{ "branch", icon = "󰘬", color = { fg = colors.purple, bg = colors.panel_alt } },
				{
					"diff",
					colored = true,
					diff_color = {
						added = { fg = colors.green },
						modified = { fg = colors.yellow },
						removed = { fg = colors.red },
					},
					symbols = { added = "+", modified = "~", removed = "-" },
				},
			},
			lualine_c = {
				{ M.file_context, color = { fg = colors.fg, bg = colors.panel } },
			},
			lualine_x = {
				{
					"diagnostics",
					sources = { "nvim_diagnostic" },
					symbols = { error = "E:", warn = "W:", info = "I:", hint = "H:" },
					sections = { "error", "warn", "info", "hint" },
					colored = true,
					update_in_insert = false,
				},
				{ M.formatter_status, color = { fg = colors.orange } },
				{ M.lsp_status, color = { fg = colors.cyan } },
				{ M.package_status, color = { fg = colors.green } },
				{ "filetype", colored = true, icon_only = false },
			},
			lualine_y = {
				{ "progress", color = { fg = colors.muted } },
			},
			lualine_z = {
				{ "location" },
			},
		},
		inactive_sections = {
			lualine_a = {},
			lualine_b = {
				{ M.project_root, icon = "󰉋", color = { fg = colors.muted } },
			},
			lualine_c = {
				{ M.file_context, color = { fg = colors.muted } },
			},
			lualine_x = { "location" },
			lualine_y = {},
			lualine_z = {},
		},
	}
end

return M
