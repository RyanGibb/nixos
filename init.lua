require('gruvbox').setup {
	terminal_colors = false,
}
vim.cmd [[colorscheme gruvbox]]
vim.api.nvim_command('hi Normal guibg=NONE ctermbg=NONE')
vim.cmd([[
  highlight SignColumn ctermbg=none guibg=none
]])

vim.o.mouse = 'a'
vim.o.mousemodel = 'extend'

vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.bo.autoindent = true
vim.bo.smartindent = true

vim.o.fixendofline = false

vim.o.conceallevel = 0
vim.wo.signcolumn = 'yes'

vim.o.smartcase = true

vim.o.spelllang = 'en'
vim.o.spellfile = os.getenv('HOME') .. '/.config/vim/spell.en.utf-8.add'
vim.opt_local.spell = true
vim.opt_local.spelllang = 'en_gb'

vim.wo.number = true
vim.api.nvim_create_augroup('numbertoggle', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter', 'FocusGained', 'InsertLeave', 'WinEnter' }, {
	group = 'numbertoggle',
	pattern = '*',
	callback = function()
		if vim.wo.number and vim.fn.mode() ~= 'i' then
			vim.wo.relativenumber = true
		end
	end,
})
vim.api.nvim_create_autocmd({ 'BufLeave', 'FocusLost', 'InsertEnter', 'WinLeave' }, {
	group = 'numbertoggle',
	pattern = '*',
	callback = function()
		if vim.wo.number then
			vim.wo.relativenumber = false
		end
	end,
})

vim.g.mapleader = ' '

vim.opt.timeout = false
-- remove warning delay
vim.opt.readonly = false

vim.opt.undodir = vim.fn.stdpath('data') .. 'undodir'
vim.opt.undofile = true

vim.opt.hlsearch = false

vim.opt.updatetime = 500

vim.o.foldlevel = 99

vim.g.vim_markdown_follow_anchor = 1

vim.o.cursorcolumn = true
vim.o.cursorline = true

local key_mapper = function(mode, key, result)
	vim.api.nvim_set_keymap(
		mode,
		key,
		result,
		{ noremap = true, silent = true }
	)
end

key_mapper('n', '<leader>w', ':w<CR>')

key_mapper('n', 'ZA', ':cquit<Enter>')

key_mapper('t', '<Esc>', '<C-\\><C-n>')

key_mapper('n', '<leader>id',
	[[<Cmd>lua vim.api.nvim_put({vim.fn.strftime('%Y-%m-%d')}, 'c', true, true)<CR>]])

key_mapper('n', '!', ':term ')

vim.keymap.set('n', '<leader>v', vim.cmd.Git)

key_mapper('n', '<leader>m', ':make<Enter>')

-- go though spelling mistakes
key_mapper('n', '<C-s>', ']s1z=')

key_mapper('v', '<C-J>', ":m '>+1<CR>gv=gv")
key_mapper('v', '<C-K>', ":m '<-2<CR>gv=gv")

key_mapper('n', '<C-d>', '<C-d>zz')
key_mapper('n', '<C-u>', '<C-u>zz')
key_mapper('n', 'n', 'nzzzv')
key_mapper('n', 'N', 'Nzzzv')

vim.keymap.set({ 'n', 'v' }, '<leader>y', [["+y]])
vim.keymap.set({ 'n', 'v' }, '<leader>p', [["+p]])
vim.keymap.set({ 'n', 'v' }, '<leader>P', [["+P]])
vim.keymap.set({ 'n', 'v' }, '<leader>d', [["+d]])
vim.keymap.set({ 'n', 'v' }, '<leader>D', [["+D]])
vim.keymap.set('n', '<leader>Y', [["+Y]])

vim.keymap.set('x', '<leader><C-p>', [["_dP]])
vim.keymap.set({ 'n', 'v' }, '<leader><C-d>', [["_d]])

vim.keymap.set('n', '<leader>S', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

vim.keymap.set('n', '<leader>tc', ':tabnew<CR>')
vim.keymap.set('n', '<leader>te', ':tabedit ')
vim.keymap.set('n', '<leader>tn', ':tabnext<CR>')
vim.keymap.set('n', '<leader>tp', ':tabprevious<CR>')
vim.keymap.set('n', '<leader>tN', ':tabmove +1<CR>')
vim.keymap.set('n', '<leader>tP', ':tabmove -1<CR>')
vim.keymap.set('n', '<leader>tq', ':tabclose<CR>')

-- if in an SSH session enable OSC 52 system clipboard
-- required as neovim can't detect alacritty capabilities as it doesn't support XTGETTCAP
if os.getenv('SSH_TTY') then
	vim.g.clipboard = {
		name = 'OSC 52',
		copy = {
			['+'] = require('vim.ui.clipboard.osc52').copy('+'),
			['*'] = require('vim.ui.clipboard.osc52').copy('*'),
		},
		paste = {
			['+'] = require('vim.ui.clipboard.osc52').paste('+'),
			['*'] = require('vim.ui.clipboard.osc52').paste('*'),
		},
	}
end

vim.api.nvim_create_autocmd('TermOpen', {
	pattern = '*',
	command = 'startinsert',
})

--- utils

require('nvim-surround').setup({})
require('Comment').setup()
vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle)

-- git gutter

vim.g.gitgutter_map_keys = 0
vim.api.nvim_set_keymap('n', ']c', '<Plug>(GitGutterNextHunk)', {})
vim.api.nvim_set_keymap('n', '[c', '<Plug>(GitGutterPrevHunk)', {})
vim.api.nvim_set_keymap('n', '<Leader>hp', '<Plug>(GitGutterPreviewHunk)', {})
vim.api.nvim_set_keymap('n', '<Leader>hs', '<Plug>(GitGutterStageHunk)', {})
vim.api.nvim_set_keymap('n', '<Leader>hu', '<Plug>(GitGutterUndoHunk)', {})
vim.cmd([[
  highlight GitGutterAdd ctermbg=none guibg=none
  highlight GitGutterDelete ctermbg=none guibg=none
  highlight GitGutterChange ctermbg=none guibg=none
]])

-- telescope

require('telescope').load_extension('fzf')
require("telescope").load_extension("undo")
require('telescope').setup {
	defaults = {
		mappings = {
			i = {
				["<C-Down>"] = require('telescope.actions').cycle_history_next,
				["<C-Up>"] = require('telescope.actions').cycle_history_prev,
			},
		},
	},
	extensions = {
		undo = {
			mappings = {
				i = {
					["<cr>"] = require("telescope-undo.actions").yank_additions,
					["<S-cr>"] = require("telescope-undo.actions").yank_deletions,
					["<C-cr>"] = require("telescope-undo.actions").restore,
					-- alternative defaults, for users whose terminals do questionable things with modified <cr>
					["<C-y>"] = require("telescope-undo.actions").yank_deletions,
					["<C-r>"] = require("telescope-undo.actions").restore,
				},
				n = {
					["y"] = require("telescope-undo.actions").yank_additions,
					["Y"] = require("telescope-undo.actions").yank_deletions,
					["u"] = require("telescope-undo.actions").restore,
				},
			},
		},
	},
}
vim.keymap.set('n', '<leader>ff', require('telescope.builtin').find_files, {})
vim.keymap.set('n', '<leader>fg', require('telescope.builtin').live_grep, {})
vim.keymap.set('n', '<leader>fv', require('telescope.builtin').git_files, {})
vim.keymap.set('n', '<leader>fb', function() require('telescope.builtin').buffers({ sort_mru = true }) end, {})
vim.keymap.set('n', '<leader>fh', require('telescope.builtin').help_tags, {})
vim.keymap.set('n', '<leader>fq', require('telescope.builtin').command_history, {})
vim.keymap.set('n', '<leader>fs', require('telescope.builtin').search_history, {})
vim.keymap.set('n', '<leader>fj', require('telescope.builtin').jumplist, {})
vim.keymap.set('n', '<leader>fm', require('telescope.builtin').marks, {})
vim.keymap.set('n', '<leader>fx', require('telescope.builtin').diagnostics, {})
vim.keymap.set('n', '<leader>fy', require('telescope.builtin').registers, {})
vim.keymap.set('n', '<leader>fr', require('telescope.builtin').lsp_references, {})
vim.keymap.set('n', '<leader>fS', require('telescope.builtin').lsp_document_symbols, {})
vim.keymap.set('n', '<leader>fc', require('telescope.builtin').lsp_incoming_calls, {})
vim.keymap.set('n', '<leader>fo', require('telescope.builtin').lsp_outgoing_calls, {})
vim.keymap.set('n', '<leader>fi', require('telescope.builtin').lsp_implementations, {})
vim.keymap.set('n', '<leader>fu', require('telescope').extensions.undo.undo, {})

-- trouble

require('trouble').setup {
	icons = false,
}

vim.keymap.set('n', '<leader>xx', function() require('trouble').toggle() end)
vim.keymap.set('n', '<leader>xw', function() require('trouble').toggle('workspace_diagnostics') end)
vim.keymap.set('n', '<leader>xd', function() require('trouble').toggle('document_diagnostics') end)
vim.keymap.set('n', '<leader>xq', function() require('trouble').toggle('quickfix') end)
vim.keymap.set('n', '<leader>xl', function() require('trouble').toggle('loclist') end)
vim.keymap.set('n', '<leader>xr', function() require('trouble').toggle('lsp_references') end)

-- vimtex
vim.cmd [[
  filetype plugin indent on
  syntax enable
]]

-- luasnip

local ls = require('luasnip')
local s = ls.snippet
local f = ls.function_node
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local sn = ls.snippet_node
local d = ls.dynamic_node

local function date_input()
	return os.date('%Y-%m-%d')
end

local function amount_spacing(args)
	local account_length = #args[1][1]
	local amount = args[2][1]
	if amount == '' then
		return ''
	end
	local desired_column = vim.g.ledger_align_at or 50
	local current_column = 2 + account_length + 2 -- 2 spaces after account
	local period_position = amount:find('%.') or (#amount + 1)
	local pre_period_length = period_position - 1
	local total_length = current_column + pre_period_length
	local spaces_needed = desired_column - total_length
	if spaces_needed < 0 then spaces_needed = 1 end
	return string.rep(' ', spaces_needed)
end

local function recursive_accounts()
	return sn(nil, {
		t({ '', '  ' }), i(1, 'Account'), f(amount_spacing, { 1, 2 }),
		c(2, {
			t(''),
			sn(nil, { i(1, '£') })
		}),
		c(3, {
			t(''),
			d(nil, recursive_accounts)
		})
	})
end

ls.add_snippets('all', {
	s('d', {
		f(date_input)
	}),
	s('ledger', {
		i(1, f(date_input)), t(' '), i(2, 'Description'),
		c(3, {
			sn(nil, { t({ '', '  ; ' }), i(1, 'Comment') }),
			t(''),
		}),
		t({ '', '  ' }), i(4, 'Account'), f(amount_spacing, { 4, 5 }),
		c(5, {
			sn(nil, { i(1, '£') }),
			t(''),
		}),
		d(6, recursive_accounts),
		t({ '', '', '' }),
	}),
})
ls.add_snippets('mail', {
	s('attach', {
		t({ '<#part filename=' }),
		i(1, '~/'),
		c(2, {
			sn(nil, { t({ ' description="', }), i(1, ''), t({ '"', }) }),
			t(''),
		}),
		t({ '><#/part>', '' }),
	}),
})


vim.keymap.set({ 'i' }, '<C-k>', function() ls.expand() end, { silent = true })
vim.keymap.set({ 'i', 's' }, '<C-l>', function() ls.jump(1) end, { silent = true })
vim.keymap.set({ 'i', 's' }, '<C-h>', function() ls.jump(-1) end, { silent = true })
vim.keymap.set({ 'i', 's' }, '<C-j>', function()
	if ls.choice_active() then
		ls.change_choice(1)
	end
end, { silent = true })

-- nvim-cmp

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
				spell = '[Spell]',
				buffer = '[Buffer]',
				path = '[Path]',
				ls = '[Luasnip]',
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
	}
})
-- `:` cmdline setup.
cmp.setup.cmdline(':', {
	sources = cmp.config.sources({
		{ name = 'path' }
	}, {
		{ name = 'cmdline' }
	})
})

-- vim-ledger

vim.g.ledger_fuzzy_account_completion = true
vim.g.ledger_extra_options = '--pedantic'
vim.g.ledger_align_at = 50
vim.g.ledger_accounts_cmd = 'ledger accounts --add-budget'
vim.g.ledger_date_format = '%Y-%m-%d'

vim.cmd([[
autocmd FileType ledger nnoremap <buffer> <leader>e :call ledger#entry()<CR>
]])

-- session management

local session_dir = vim.fn.stdpath('data') .. '/sessions/'

local function ensure_dir_exists(dir)
	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir, 'p')
	end
end

local function sanitize_path(path)
	return path:gsub('[\\/]+', '_'):gsub('^_*', ''):gsub('_*$', '')
end

local function session_file_name(name)
	local cwd = vim.fn.getcwd()
	local sanitized_cwd = sanitize_path(cwd)
	if name and #name > 0 then
		return session_dir .. 'session:' .. sanitized_cwd .. ':' .. sanitize_path(name) .. '.vim'
	else
		return session_dir .. 'session:' .. sanitized_cwd .. '.vim'
	end
end

local function save_session(args)
	ensure_dir_exists(session_dir)
	local session_file = session_file_name(args.args)
	vim.cmd('mksession! ' .. vim.fn.fnameescape(session_file))
end

local function load_session(args)
	local session_file = session_file_name(args.args)
	if vim.fn.filereadable(session_file) == 1 then
		vim.cmd('source ' .. vim.fn.fnameescape(session_file))
	else
		print('No session file found for ' .. (args.args == '' and 'this directory' or args.args))
	end
end

local function session_completion(arg_lead, cmd_line, cursor_pos)
	local files = vim.fn.globpath(session_dir, 'session:' .. sanitize_path(vim.fn.getcwd()) .. ':*', 0, 1)
	local sessions = {}
	for _, file in ipairs(files) do
		local session = file:match('session:' .. sanitize_path(vim.fn.getcwd()) .. ':(.+)%.vim$')
		if session and session:find(arg_lead, 1, true) == 1 then
			table.insert(sessions, session)
		end
	end
	return sessions
end

vim.api.nvim_create_autocmd('VimLeave', {
	pattern = '*',
	callback = function() save_session({ args = '' }) end,
})

vim.api.nvim_create_user_command('SaveSession', save_session, { nargs = '?', complete = session_completion })
vim.api.nvim_create_user_command('LoadSession', load_session, { nargs = '?', complete = session_completion })

key_mapper('n', '<leader>ss', ':SaveSession<CR>')
key_mapper('n', '<leader>sl', ':LoadSession<CR>')

-- org-mode

-- Open agenda prompt: <Leader>oa
-- Open capture prompt: <Leader>oc
-- In any orgmode buffer press g? for help
require('orgmode').setup({
	org_agenda_files = { '~/vault/agenda/*.org' },
	org_default_notes_file = '~/vault/refile.org',
})

-- calendar

require('calendar')

-- free real-estate
-- <leader>q
-- <leader>n
-- <leader>;
-- <leader>h
-- <leader>j
-- <leader>k
-- <leader>e
-- <leader>b

vim.cmd([[
augroup RememberView
  autocmd!
  autocmd BufWinLeave * let b:win_view = winsaveview()
  autocmd BufWinEnter * if exists('b:win_view') | call winrestview(b:win_view) | endif
augroup END
]])
-- lspconfig

--- underline errors rather than highlight
vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
	vim.lsp.diagnostic.on_publish_diagnostics, {
		underline = true,
		---virtual_text = true,
		signs = true,
		update_in_insert = true,
		float = true,
	}
)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
On_attach = function(client, bufnr)
	-- Mappings.
	-- See `:help vim.lsp.*` for documentation on any of the below functions
	local bufopts = function(desc)
		return { noremap = true, silent = true, buffer = bufnr, desc = desc }
	end
	vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts('Hover'))
	vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts('Goto definition'))
	vim.keymap.set('n', '[d', vim.diagnostic.goto_next, bufopts('Goto next issue'))
	vim.keymap.set('n', ']d', vim.diagnostic.goto_prev, bufopts('Goto prev issue'))
	vim.keymap.set('n', '<leader>li', vim.lsp.buf.implementation, bufopts('Goto implementation'))
	vim.keymap.set('n', '<leader>lt', vim.lsp.buf.type_definition, bufopts('Goto type definition'))
	vim.keymap.set('n', '<leader>lr', vim.lsp.buf.references, bufopts('Show references'))
	vim.keymap.set('n', '<leader>la', vim.lsp.buf.code_action, bufopts('Code action'))
	vim.keymap.set('n', '<leader>lR', vim.lsp.buf.rename, bufopts('Rename'))
	vim.keymap.set('n', '<leader>lf', function() vim.lsp.buf.format { async = true } end, bufopts('Format'))
	vim.keymap.set('n', '<leader>le', vim.diagnostic.open_float, bufopts('Get error'))
end

-- Add additional capabilities supported by nvim-cmp
Capabilities = vim.tbl_deep_extend('force',
	vim.lsp.protocol.make_client_capabilities(),
	require('cmp_nvim_lsp').default_capabilities()
)
Capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false

local lspconfig = require('lspconfig')

-- Enable some language servers with the additional completion capabilities offered by nvim-cmp
local servers = { 'nixd', 'ocamllsp', 'clangd', 'rust_analyzer', 'pyright', 'tsserver', 'gopls', 'typst_lsp' }
for _, lsp in ipairs(servers) do
	lspconfig[lsp].setup {
		on_attach = On_attach,
		capabilities = Capabilities,
	}
end

lspconfig['lua_ls'].setup {
	on_attach = On_attach,
	capabilities = Capabilities,
	settings = {
		Lua = {
			runtime = {
				-- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
				version = 'LuaJIT',
			},
			diagnostics = {
				-- Get the language server to recognize the `vim` global
				globals = { 'vim' },
			},
			workspace = {
				-- Make the server aware of Neovim runtime files
				library = vim.api.nvim_get_runtime_file('', true),
				checkThirdParty = false,
			},
			-- Do not send telemetry data containing a randomized but unique identifier
			telemetry = {
				enable = false,
			},
		},
	},
}

-- wrapper around lspconfig['ltex-ls'] with support for hide false positive
require('ltex-ls').setup {
	on_attach = On_attach,
	capabilities = Capabilities,
	use_spellfile = false,
	filetypes = { 'markdown', 'latex', 'tex', 'bib', 'plaintext', 'mail', 'gitcommit', 'typst' },
	settings = {
		ltex = {
			flags = { debounce_text_changes = 300 },
			language = 'en-GB',
			sentenceCacheSize = 2000,
			disabledRules = {
				['en-GB'] = {
					'MORFOLOGIK_RULE_EN_GB',
					'OXFORD_SPELLING_Z_NOT_S',
				},
			},
		},
	},
}

vim.cmd [[autocmd BufWritePre <buffer> lua vim.lsp.buf.format()]]

-- dap

-- TODO
-- stdout
-- args

local dap = require('dap')
dap.adapters.ocamlearlybird = {
	type = 'executable',
	command = 'ocamlearlybird',
	args = { 'debug' }
}

dap.configurations.ocaml = {
	{
		name = 'OCaml',
		type = 'ocamlearlybird',
		request = 'launch',
		program = function()
			local path = vim.fn.input({
				prompt = 'Path to executable: ',
				default = vim.fn.getcwd() .. '/_build/default/bin/',
				completion = 'file'
			})
			return (path and path ~= "") and path or dap.ABORT
		end,
	},
}

vim.keymap.set('n', '<leader>;c', function() require('dap').continue() end)
vim.keymap.set('n', '<leader>;s', function() require('dap').step_over() end)
vim.keymap.set('n', '<leader>;i', function() require('dap').step_into() end)
vim.keymap.set('n', '<leader>;o', function() require('dap').step_out() end)
vim.keymap.set('n', '<leader>;b', function() require('dap').toggle_breakpoint() end)
vim.keymap.set('n', '<leader>;m',
	function() require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end)
vim.keymap.set('n', '<leader>;r', function() require('dap').repl.open() end)
vim.keymap.set('n', '<leader>;l', function() require('dap').run_last() end)
vim.keymap.set('n', '<leader>;f', function()
	local widgets = require('dap.ui.widgets')
	widgets.centered_float(widgets.frames)
end)
vim.keymap.set('n', '<leader>;S', function()
	local widgets = require('dap.ui.widgets')
	widgets.centered_float(widgets.scopes)
end)
