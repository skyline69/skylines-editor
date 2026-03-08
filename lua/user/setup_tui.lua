local M = {}

local bundles = require("user.bundles")
local languages = require("user.languages")
local profile_mod = require("user.profile")
local qol = require("user.qol")

local pages = {
	{ id = "overview", label = "Overview" },
	{ id = "features", label = "Features" },
	{ id = "languages", label = "Languages" },
	{ id = "qol", label = "QoL" },
	{ id = "review", label = "Review" },
}

local function copy_profile(profile)
	local normalized = profile_mod.normalize(profile)
	return {
		version = normalized.version,
		features = vim.deepcopy(normalized.features),
		languages = vim.deepcopy(normalized.languages),
		qol = vim.deepcopy(normalized.qol),
	}
end

local function contains(values, value)
	return vim.tbl_contains(values, value)
end

local function toggle(values, value)
	if value == "core" then
		return values
	end

	local next_values = {}
	local found = false
	for _, item in ipairs(values) do
		if item == value then
			found = true
		else
			next_values[#next_values + 1] = item
		end
	end

	if not found then
		next_values[#next_values + 1] = value
	end

	return next_values
end

local function pad(str, width)
	local text = str or ""
	if #text >= width then
		return text:sub(1, width - 1) .. " "
	end
	return text .. string.rep(" ", width - #text)
end

local function page_index(state, page_id)
	for index, page in ipairs(pages) do
		if page.id == page_id then
			return index
		end
	end
	return 1
end

local function get_items(state)
	if pages[state.page].id == "features" then
		local items = {}
		for _, item in ipairs(bundles.get_all()) do
			items[#items + 1] = {
				id = item.id,
				label = item.label,
				description = item.description,
				selected = contains(state.profile.features, item.id),
				locked = item.id == "core",
			}
		end
		return items
	end

	if pages[state.page].id == "languages" then
		local items = {}
		for _, item in ipairs(languages.get_all()) do
			items[#items + 1] = {
				id = item.id,
				label = item.label,
				description = item.description,
				selected = contains(state.profile.languages, item.id),
				tools = table.concat(item.tools or {}, ", "),
			}
		end
		return items
	end

	if pages[state.page].id == "qol" then
		local items = {}
		for _, item in ipairs(qol.get_all()) do
			local available = qol.is_available(item.id, state.profile.languages)
			local reason = nil
			if not available and item.requires_languages and #item.requires_languages > 0 then
				reason = "Requires " .. table.concat(item.requires_languages, ", ")
			end
			items[#items + 1] = {
				id = item.id,
				label = item.label,
				description = item.description,
				selected = contains(state.profile.qol, item.id),
				available = available,
				reason = reason,
			}
		end
		return items
	end

	return {}
end

local function render(state)
	local sidebar_width = 18
	local lines = {}
	local items = get_items(state)
	local active_page = pages[state.page].id
	local resolved_languages = languages.resolve(state.profile.languages)
	local effective_features = vim.deepcopy(state.profile.features)

	if #resolved_languages.languages > 0 and not contains(effective_features, "lsp") then
		effective_features[#effective_features + 1] = "lsp"
	end

	for _, required in ipairs(resolved_languages.required_features) do
		if not contains(effective_features, required) then
			effective_features[#effective_features + 1] = required
		end
	end

	local content = {
		overview = {
			"Skyline Setup",
			"",
			"Build a lightweight Neovim profile and opt into language tooling only where you want it.",
			"",
			"Use the sidebar pages to review feature bundles, language support, and the exact tooling that will be enabled.",
			"",
			"Save writes your profile to disk.",
			"Plugin changes apply on restart; new plugins or tools may need :Lazy sync and Mason installation afterward.",
		},
		features = {},
		languages = {},
		qol = {},
		review = {
			"Selected features: " .. table.concat(state.profile.features, ", "),
			"Effective features: " .. table.concat(effective_features, ", "),
			"Selected languages: " .. (#state.profile.languages > 0 and table.concat(state.profile.languages, ", ") or "none"),
			"Selected QoL: " .. (#state.profile.qol > 0 and table.concat(profile_mod.normalize(state.profile).qol, ", ") or "none"),
			"Mason packages: " .. (#resolved_languages.mason_packages > 0 and table.concat(resolved_languages.mason_packages, ", ") or "none"),
			"LSP servers: " .. (#resolved_languages.servers > 0 and table.concat(resolved_languages.servers, ", ") or "none"),
			"",
			"Save this profile when the summary looks right.",
			"If you changed plugins or languages, restart Neovim to fully apply the new setup.",
		},
	}

	for _, item in ipairs(items) do
		local marker = item.selected and "[x]" or "[ ]"
		if item.locked then
			marker = "[*]"
		elseif item.available == false then
			marker = "[-]"
		end

		local extra = item.tools and ("  {" .. item.tools .. "}") or ""
		if item.reason then
			extra = extra .. "  (" .. item.reason .. ")"
		end
		content[active_page][#content[active_page] + 1] = string.format("%s %s - %s%s", marker, item.label, item.description, extra)
	end

	local max_lines = math.max(#pages + 2, #content[active_page] + 4)
	for i = 1, max_lines do
		local sidebar = ""
		if i == 1 then
			sidebar = "Setup"
		elseif i > 2 and pages[i - 2] then
			local page = pages[i - 2]
			sidebar = (state.page == (i - 2) and "> " or "  ") .. page.label
		end

		local main = content[active_page][i - 1] or ""
		lines[#lines + 1] = pad(sidebar, sidebar_width) .. " " .. main
	end

	lines[#lines + 1] = ""
	lines[#lines + 1] = "Controls: j/k move  h/l page  <Space>/Enter toggle  s save  r minimal  D defaults  q cancel"

	vim.api.nvim_set_option_value("modifiable", true, { buf = state.buf })
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = state.buf })

	local line = state.cursor + 1
	if active_page == "overview" then
		line = 3
	elseif active_page == "review" then
		line = 2
	end

	pcall(vim.api.nvim_win_set_cursor, state.win, { line, 0 })
end

local function close(state)
	if vim.api.nvim_tabpage_is_valid(state.tabpage) then
		vim.cmd("tabclose")
	end
end

local function save_and_close(state)
	local saved = profile_mod.save(state.profile)
	close(state)
	vim.notify("Skyline setup saved. Restart Neovim to apply plugin changes.", vim.log.levels.INFO)
	if state.on_save then
		state.on_save(saved)
	end
end

local function move(state, delta)
	local items = get_items(state)
	if #items == 0 then
		return
	end

	state.cursor = state.cursor + delta
	if state.cursor < 1 then
		state.cursor = #items
	elseif state.cursor > #items then
		state.cursor = 1
	end
	render(state)
end

local function change_page(state, delta)
	state.page = state.page + delta
	if state.page < 1 then
		state.page = #pages
	elseif state.page > #pages then
		state.page = 1
	end
	state.cursor = 1
	render(state)
end

local function toggle_current(state)
	local items = get_items(state)
	local item = items[state.cursor]
	if not item or item.locked then
		return
	end

	if pages[state.page].id == "features" then
		state.profile.features = toggle(state.profile.features, item.id)
	elseif pages[state.page].id == "languages" then
		state.profile.languages = toggle(state.profile.languages, item.id)
		state.profile = copy_profile(state.profile)
	elseif pages[state.page].id == "qol" then
		if item.available ~= false then
			state.profile.qol = toggle(state.profile.qol, item.id)
		end
	end

	render(state)
end

function M.open(opts)
	local state = {
		profile = copy_profile((opts and opts.profile) or profile_mod.load() or profile_mod.default_minimal()),
		page = page_index({}, (opts and opts.page) or "overview"),
		cursor = 1,
		first_run = opts and opts.first_run or false,
		on_save = opts and opts.on_save or nil,
	}

	vim.cmd("tabnew")
	state.tabpage = vim.api.nvim_get_current_tabpage()
	state.win = vim.api.nvim_get_current_win()
	state.buf = vim.api.nvim_get_current_buf()

	vim.api.nvim_set_option_value("buftype", "nofile", { buf = state.buf })
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = state.buf })
	vim.api.nvim_set_option_value("swapfile", false, { buf = state.buf })
	vim.api.nvim_set_option_value("modifiable", false, { buf = state.buf })
	vim.api.nvim_set_option_value("number", false, { win = state.win })
	vim.api.nvim_set_option_value("relativenumber", false, { win = state.win })
	vim.api.nvim_set_option_value("cursorline", true, { win = state.win })
	vim.api.nvim_set_option_value("signcolumn", "no", { win = state.win })
	vim.api.nvim_buf_set_name(state.buf, "Skyline Setup")

	local map = function(lhs, rhs)
		vim.keymap.set("n", lhs, rhs, { buffer = state.buf, silent = true, nowait = true })
	end

	map("j", function()
		move(state, 1)
	end)
	map("<Down>", function()
		move(state, 1)
	end)
	map("k", function()
		move(state, -1)
	end)
	map("<Up>", function()
		move(state, -1)
	end)
	map("h", function()
		change_page(state, -1)
	end)
	map("<Left>", function()
		change_page(state, -1)
	end)
	map("l", function()
		change_page(state, 1)
	end)
	map("<Right>", function()
		change_page(state, 1)
	end)
	map("<Tab>", function()
		change_page(state, 1)
	end)
	map("<S-Tab>", function()
		change_page(state, -1)
	end)
	map("<Space>", function()
		toggle_current(state)
	end)
	map("<CR>", function()
		toggle_current(state)
	end)
	map("s", function()
		save_and_close(state)
	end)
	map("r", function()
		state.profile = copy_profile(profile_mod.default_minimal())
		state.page = page_index(state, "review")
		state.cursor = 1
		render(state)
	end)
	map("D", function()
		state.profile = copy_profile(profile_mod.default_popular())
		state.page = page_index(state, "review")
		state.cursor = 1
		render(state)
	end)
	map("q", function()
		close(state)
		if state.first_run then
			vim.notify("Skyline setup skipped. Minimal profile remains active for this session.", vim.log.levels.WARN)
		end
	end)
	map("<Esc>", function()
		close(state)
		if state.first_run then
			vim.notify("Skyline setup skipped. Minimal profile remains active for this session.", vim.log.levels.WARN)
		end
	end)

	render(state)
end

return M
