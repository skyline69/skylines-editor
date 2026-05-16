local M = {}

function M.from(items, order, project)
	project = project
		or function(id, item)
			return { id = id, label = item.label, description = item.description }
		end

	local api = {}

	function api.is_valid(id)
		return items[id] ~= nil
	end

	function api.get(id)
		return items[id]
	end

	function api.get_all()
		local out = {}
		for _, id in ipairs(order) do
			local item = items[id]
			if item then
				out[#out + 1] = project(id, item)
			end
		end
		return out
	end

	function api.iter()
		return ipairs(order)
	end

	return api
end

return M
