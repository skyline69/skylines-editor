local M = {}

local function as_list(value)
	if value == nil then
		return {}
	end
	if type(value) == "string" then
		return { value }
	end
	return vim.deepcopy(value)
end

local function as_set(values)
	local result = {}
	for _, value in ipairs(as_list(values)) do
		result[value] = true
	end
	return result
end

local function install_languages(treesitter, languages)
	if #languages == 0 or type(treesitter.install) ~= "function" then
		return
	end

	local ok, err = pcall(treesitter.install, languages)
	if not ok then
		vim.notify(("Treesitter parser install failed: %s"):format(err), vim.log.levels.WARN)
	end
end

function M.setup(opts)
	opts = opts or {}
	local ok, treesitter = pcall(require, "nvim-treesitter")
	if not ok or type(treesitter.setup) ~= "function" then
		local ok_legacy, configs = pcall(require, "nvim-treesitter.configs")
		if ok_legacy then
			configs.setup(opts)
			return
		end
		error(treesitter)
	end

	local setup_opts = {}

	if opts.install_dir then
		setup_opts.install_dir = opts.install_dir
	end
	treesitter.setup(setup_opts)

	local languages = as_list(opts.ensure_installed)
	if opts.auto_install ~= false then
		install_languages(treesitter, languages)
	end

	local highlight_enabled = opts.highlight and opts.highlight.enable == true
	local indent_enabled = opts.indent and opts.indent.enable == true
	local indent_disabled = as_set(opts.indent and opts.indent.disable)
	if not highlight_enabled and not indent_enabled then
		return
	end

	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("SkylineTreesitter", { clear = true }),
		pattern = languages,
		callback = function(event)
			local filetype = vim.bo[event.buf].filetype
			if highlight_enabled then
				pcall(vim.treesitter.start, event.buf)
			end
			if indent_enabled and not indent_disabled[filetype] then
				vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end
		end,
	})
end

return M
