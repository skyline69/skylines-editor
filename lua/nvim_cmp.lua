local cmp = require("cmp")
local luasnip = require("luasnip")

require("luasnip.loaders.from_vscode").lazy_load()

local borderstyle = {
	border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
	winhighlight = "Normal:CmpPmenu,CursorLine:PmenuSel,Search:None",
}

local kind_icons = {
	Text = "",
	Method = "m",
	Function = "󰊕",
	Constructor = "",
	Field = "",
	Variable = "",
	Class = "",
	Interface = "",
	Module = "",
	Property = " ",
	Unit = "",
	Value = "󰎠",
	Enum = "",
	Keyword = "󰌋",
	Snippet = "",
	Color = "󰏘",
	File = "󰈙",
	Reference = "",
	Folder = "󰉋",
	EnumMember = "",
	Constant = "󰏿",
	Struct = "",
	Event = "",
	Operator = "󰆕",
	TypeParameter = " ",
}

cmp.setup({
	completion = {
		completeopt = "menu,menuone,preview,noinsert",
	},
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-u>"] = cmp.mapping.scroll_docs(-4), -- Up
		["<C-d>"] = cmp.mapping.scroll_docs(4), -- Down
		["<C-Space>"] = cmp.mapping.complete(),
		-- ["<CR>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
	-- 	["<Tab>"] = cmp.mapping(function(fallback)
	-- 		if cmp.visible() then
	-- 			cmp.confirm({
	-- 				behavior = cmp.ConfirmBehavior.Insert,
	-- 				select = true,
	-- 			})
	-- 		else
	-- 			fallback()
	-- 		end
	-- 	end, { "i", "s" }),
	}),
	formatting = {
		fields = { "kind", "abbr", "menu" },
		format = function(entry, vim_item)
			vim_item.menu = ({
				nvim_lsp = "[LSP]",
				luasnip = "[Snip]",
				buffer = "[Buff]",
				path = "[Path]",
			})[entry.source.name]

			-- -- for tailwind colors
			-- if vim_item.kind == "Color" then
			-- 	vim_item = require("cmp-tailwind-colors").format(entry, vim_item)
			-- 	if vim_item.kind ~= "Color" then
			-- 		vim_item.menu = "Color"
			-- 		return vim_item
			-- 	end
			-- end

			vim_item.kind = string.format("%s", kind_icons[vim_item.kind])
			return vim_item
		end,
	},
	sources = {
		{ name = "nvim_lsp" },
		{ name = "nvim_lsp_signature_help" },
		{ name = "buffer" },
		{ name = "luasnip" },
	},
	duplicates = {
		nvim_lsp = 1,
		luasnip = 1,
		buffer = 1,
		path = 1,
	},
	window = {
		completion = borderstyle,
		documentation = borderstyle,
	},
	experimental = {
		ghost_text = false,
		native_menu = false,
	},
})
