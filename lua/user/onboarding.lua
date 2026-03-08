local M = {}

local function bundle_ids()
	local bundles = require("user.bundles").get_all()
	local ids = {}

	for _, bundle in ipairs(bundles) do
		if bundle.id ~= "core" then
			ids[#ids + 1] = bundle.id
		end
	end

	return ids, bundles
end

function M.choose_bundles()
	local selected = { "core" }
	local ids, all_bundles = bundle_ids()
	local by_id = {}

	for _, bundle in ipairs(all_bundles) do
		by_id[bundle.id] = bundle
	end

	local first_choice = vim.fn.confirm(
		"Choose initial setup",
		"&Minimal core only\n&Customize bundles\n&Install everything",
		1
	)

	if first_choice == 3 then
		for _, id in ipairs(ids) do
			selected[#selected + 1] = id
		end
		return selected
	end

	if first_choice ~= 2 then
		return selected
	end

	for _, id in ipairs(ids) do
		local bundle = by_id[id]
		local install = vim.fn.confirm(
			string.format("Install %s?\n%s", bundle.label, bundle.description),
			"&Yes\n&No",
			2
		)

		if install == 1 then
			selected[#selected + 1] = id
		end
	end

	return selected
end

return M
