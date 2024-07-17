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
	vim.keymap.set('n', '<leader>gi', vim.lsp.buf.implementation, bufopts('Goto implementation'))
	vim.keymap.set('n', '<leader>gt', vim.lsp.buf.type_definition, bufopts('Goto type definition'))
	vim.keymap.set('n', '[d', vim.diagnostic.goto_next, bufopts('Goto next issue'))
	vim.keymap.set('n', ']d', vim.diagnostic.goto_prev, bufopts('Goto prev issue'))
	vim.keymap.set('n', '<leader>gf', vim.lsp.buf.references, bufopts('Show references'))
	vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts('Code action'))
	vim.keymap.set('n', '<leader>cr', vim.lsp.buf.rename, bufopts('Rename'))
	vim.keymap.set('n', '<leader>cf', function() vim.lsp.buf.format { async = true } end, bufopts('Format'))
	vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, bufopts('Get error'))
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
