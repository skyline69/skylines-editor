local M = {}

local islist = vim.islist or vim.tbl_islist

function M.as_list(value)
	if value == nil then
		return {}
	end
	if type(value) == "string" then
		return { value }
	end
	if type(value) ~= "table" then
		return {}
	end
	if value[1] ~= nil or islist(value) then
		return value
	end
	return { value }
end

function M.safe_require(name)
	local ok, mod = pcall(require, name)
	if not ok then
		return nil, mod
	end
	return mod
end

return M
