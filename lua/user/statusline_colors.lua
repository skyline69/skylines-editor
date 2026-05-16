local M = {}

M.fallback = {
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

local function hex(value)
	if type(value) ~= "number" then
		return nil
	end
	return string.format("#%06x", value)
end

local function hl_color(name, field, fallback)
	local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
	if not ok or type(hl) ~= "table" then
		return fallback
	end
	return hex(hl[field]) or fallback
end

function M.resolve()
	local f = M.fallback
	return {
		bg = hl_color("Normal", "bg", f.bg),
		fg = hl_color("Normal", "fg", f.fg),
		muted = hl_color("Comment", "fg", f.muted),
		panel = hl_color("StatusLine", "bg", f.panel),
		panel_alt = hl_color("CursorLine", "bg", f.panel_alt),
		blue = hl_color("Function", "fg", f.blue),
		cyan = hl_color("Special", "fg", f.cyan),
		green = hl_color("String", "fg", f.green),
		yellow = hl_color("WarningMsg", "fg", f.yellow),
		orange = hl_color("Constant", "fg", f.orange),
		red = hl_color("ErrorMsg", "fg", f.red),
		purple = hl_color("Keyword", "fg", f.purple),
	}
end

return M
