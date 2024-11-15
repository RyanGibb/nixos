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

vim.keymap.set('n', '<leader>;c', function() require('dap').continue() end, { desc = 'DAP continue' })
vim.keymap.set('n', '<leader>;s', function() require('dap').step_over() end, { desc = 'DAP step over' })
vim.keymap.set('n', '<leader>;i', function() require('dap').step_into() end, { desc = 'DAP step into' })
vim.keymap.set('n', '<leader>;o', function() require('dap').step_out() end, { desc = 'DAP step out' })
vim.keymap.set('n', '<leader>;b', function() require('dap').toggle_breakpoint() end, { desc = 'DAP breakpoint' })
vim.keymap.set('n', '<leader>;m',
	function() require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end, { desc = 'DAP breakpoint message' })
vim.keymap.set('n', '<leader>;r', function() require('dap').repl.open() end, { desc = 'DAP repl' })
vim.keymap.set('n', '<leader>;l', function() require('dap').run_last() end, { desc = 'DAP run last' })
vim.keymap.set('n', '<leader>;f', function()
	local widgets = require('dap.ui.widgets')
	widgets.centered_float(widgets.frames)
end, { desc = 'DAP frames' })
vim.keymap.set('n', '<leader>;S', function()
	local widgets = require('dap.ui.widgets')
	widgets.centered_float(widgets.scopes)
end, { desc = 'DAP scopes' })
