local cmp = require 'cmp'

cmp.setup {
	snippet = {
		expand = function(args)
			require('luasnip').lsp_expand(args.body)
		end,
	},
	formatting = {
		format = function(entry, vim_item)
			vim_item.menu = ({
				omni = '[Omni]',
				nvim_lsp = '[LSP]',
				nvim_lsp_signature_help = '[Signature]',
				dictionary = '[Dictionary]',
				buffer = '[Buffer]',
				path = '[Path]',
				ls = '[Luasnip]',
				orgmode = '[Orgmode]',
			})[entry.source.name]
			return vim_item
		end,
	},
	mapping = {
		['<C-y>'] = {
			i = cmp.mapping.confirm({ select = false }),
			c = cmp.mapping.confirm({ select = false }),
		},
		['<C-e>'] = {
			i = cmp.mapping.abort(),
			c = cmp.mapping.abort(),
		},
		['<C-Space>'] = {
			i = cmp.mapping.complete(),
			c = cmp.mapping.complete(),
		},
		['<Down>'] = {
			i = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
			c = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
		},
		['<Up>'] = {
			i = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
			c = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
		},
	},
	sources = cmp.config.sources({
		{ name = 'orgmode',                 priority = 1100 },
		{ name = 'nvim_lsp_signature_help', priority = 1000 },
		{ name = 'nvim_lsp',                priority = 900 },
		{ name = 'luasnip',                 priority = 800 },
		{ name = 'omni',                    priority = 700 },
		{ name = 'buffer',                  priority = 600 },
		{ name = 'path',                    priority = 500 },
		{
			name = 'dictionary',
			priority = 400,
			keyword_length = 2,
		}
		,
	}),
	sorting = {
		priority_weight = 2,
		comparators = {
			cmp.config.compare.offset,
			-- cmp.config.compare.scopes,
			cmp.config.compare.score,
			cmp.config.compare.recently_used,
			cmp.config.compare.locality,
			cmp.config.compare.kind,
			-- cmp.config.compare.sort_text,
			-- cmp.config.compare.length,
			cmp.config.compare.order,
		},
	},
}
-- `/` cmdline setup.
cmp.setup.cmdline('/', {
	sources = {
		{ name = 'buffer' }
	},
	completion = {
		autocomplete = false
	}
})
-- `:` cmdline setup.
cmp.setup.cmdline(':', {
	sources = cmp.config.sources({
		{ name = 'path' }
	}, {
		{ name = 'cmdline' }
	}),
	completion = {
		autocomplete = false
	}
})
