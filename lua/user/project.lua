local M = {}

local default_markers = {
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

local function has_marker(path, markers)
	local uv = vim.uv or vim.loop
	for _, marker in ipairs(markers) do
		if uv.fs_stat(vim.fs.joinpath(path, marker)) then
			return true
		end
	end
	return false
end

function M.find_root(path, markers)
	markers = markers or default_markers
	local current = path
	while current and current ~= "" do
		if has_marker(current, markers) then
			return current
		end
		local parent = vim.fs.dirname(current)
		if not parent or parent == current then
			return nil
		end
		current = parent
	end
	return nil
end

function M.root_for_buf(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local file = vim.api.nvim_buf_get_name(bufnr)
	local start = file == "" and vim.uv.cwd() or vim.fs.dirname(file)
	return M.find_root(start) or vim.uv.cwd()
end

function M.root_name(bufnr)
	local root = M.root_for_buf(bufnr)
	return root and vim.fs.basename(root) or vim.fs.basename(vim.uv.cwd())
end

function M.relative_path(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local file = vim.api.nvim_buf_get_name(bufnr)
	if file == "" then
		return "[No Name]"
	end
	local root = M.root_for_buf(bufnr)
	if root and vim.startswith(file, root .. "/") then
		return file:sub(#root + 2)
	end
	return vim.fn.fnamemodify(file, ":~:.")
end

return M
