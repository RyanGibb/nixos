local cmp = require 'cmp'

cmp.register_source('markdown_headers', setmetatable({}, {
	__index = {
		get_debug_name = function()
			return "markdown_headers"
		end,

		is_available = function()
			return vim.opt.filetype:get() == 'markdown'
		end,

		get_trigger_characters = function()
			return { '#' }
		end,

		complete = function(self, params, callback)
			local filename = params.context.cursor_before_line:match("%[.-%]%((.-)#")
			local headers = {}
			local process_line = function(line)
				if line:match("^#+") then
					local _, _, fragment, text = line:find("(#+)%s*(.*)")
					table.insert(headers, {
						label = text,
						insertText = "#" .. text,
						filterText = "#" .. text,
						sortText = text,
					})
				end
			end
			if filename ~= nil then
				if #filename == 0 then
					local buf_id = vim.api.nvim_get_current_buf()
					for i = 0, vim.api.nvim_buf_line_count(buf_id) - 1 do
						local line = vim.api.nvim_buf_get_lines(buf_id, i, i + 1, false)[1]
						process_line(line)
					end
				elseif vim.uv.fs_stat(filename).type == 'file' then
					local lines = vim.fn.readfile(filename)
					for i, line in ipairs(lines) do
						process_line(line)
					end
				end
			end
			callback({
				items = headers,
				isIncomplete = true
			})
		end,
	}
}))

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
				spell = '[Spell]',
				buffer = '[Buffer]',
				path = '[Path]',
				ls = '[Luasnip]',
				markdown_headers = '[Markdown headers]',
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
		{ name = "markdown_headers",        priority = 1100 },
		{ name = 'nvim_lsp_signature_help', priority = 1000 },
		{ name = 'nvim_lsp',                priority = 900 },
		{ name = 'luasnip',                 priority = 800 },
		{ name = 'omni',                    priority = 700 },
		{ name = 'buffer',                  priority = 600 },
		{ name = 'path',                    priority = 500 },
		{
			name = 'spell',
			priority = 400,
			option = { preselect_correct_word = false }
		},
	}),
	sorting = {
		priority_weight = 2,
		comparators = {
			cmp.config.compare.offset,
			cmp.config.compare.exact,
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
