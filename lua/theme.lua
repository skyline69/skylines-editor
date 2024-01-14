local palettes = {
	carbonfox = {
    sel0 = "#3F3351",
    -- fg3 = "#333333",
    green = "#03C988",
	},
}

local specs = {
	all = {
		syntax = {
			keyword = "magenta",
		},
	},
}


require("nightfox").setup({ palettes = palettes, specs = specs, groups = groups })
