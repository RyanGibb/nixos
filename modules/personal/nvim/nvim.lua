require("gruvbox").setup{}
vim.cmd [[colorscheme gruvbox]]
vim.api.nvim_command('hi Normal guibg=NONE ctermbg=NONE')

vim.g.airline_theme = 'bubblegum'

vim.o.mouse = 'a'
vim.o.clipboard = 'unnamedplus'

vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.bo.autoindent = true
vim.bo.smartindent = true

vim.o.fixendofline = false

vim.o.conceallevel = 0
vim.wo.signcolumn = "yes"
vim.opt.colorcolumn = '80,120'

vim.o.smartcase = true

vim.o.spelllang = 'en'
vim.o.spellfile = os.getenv('HOME')..'/.config/vim/spell.en.utf-8.add'
vim.opt_local.spell = true
vim.opt_local.spelllang = 'en_gb'

vim.wo.number = true
vim.api.nvim_create_augroup('numbertoggle', {clear = true})
vim.api.nvim_create_autocmd({'BufEnter', 'FocusGained', 'InsertLeave', 'WinEnter'}, {
	group = 'numbertoggle',
	pattern = '*',
	callback = function()
		if vim.wo.number and vim.fn.mode() ~= 'i' then
			vim.wo.relativenumber = true
		end
	end,
})
vim.api.nvim_create_autocmd({'BufLeave', 'FocusLost', 'InsertEnter', 'WinLeave'}, {
	group = 'numbertoggle',
	pattern = '*',
	callback = function()
		if vim.wo.number then
			vim.wo.relativenumber = false
		end
	end,
})

vim.g.mapleader = ' '

local key_mapper = function(mode, key, result)
	vim.api.nvim_set_keymap(
		mode,
		key,
		result,
		{noremap = true, silent = true}
	)
end

key_mapper('n', '<leader>h', '<C-w>h')
key_mapper('n', '<leader>j', '<C-w>j')
key_mapper('n', '<leader>k', '<C-w>k')
key_mapper('n', '<leader>l', '<C-w>l')

key_mapper('n', 'ZA', ':cquit<Enter>')

key_mapper('t', '<Esc>', '<C-\\><C-n>')

vim.api.nvim_create_autocmd('TermOpen', {
	pattern = '*',
	command = 'startinsert',
})

--- obsidian

require('obsidian').setup({
	dir = "~/vault",
	note_id_func = function(title)
	local suffix = ""
		if title ~= nil then
			suffix = " " .. title
		end
		return tostring(os.date("%Y-%m-%d")) .. suffix
	end,
	disable_frontmatter = true,
	attachments = {
		img_folder = "",
	},
	ui = {
		enable = false,
	},
})
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
vim.keymap.set('n', '<leader>fc', builtin.command_history, {})
vim.keymap.set('n', '<leader>fs', builtin.search_history, {})
vim.keymap.set('n', '<leader>fj', builtin.jumplist, {})

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
local on_attach = function(client, bufnr)
	-- Mappings.
	-- See `:help vim.lsp.*` for documentation on any of the below functions
	local bufopts = function(desc)
		return { noremap = true, silent = true, buffer = bufnr, desc = desc }
	end
	vim.keymap.set('n', '<leader>K', vim.lsp.buf.hover, bufopts("Hover"))
	vim.keymap.set('n', '<leader>gD', vim.lsp.buf.declaration, bufopts("Goto declaration"))
	vim.keymap.set('n', '<leader>gd', vim.lsp.buf.definition, bufopts("Goto definition"))
	vim.keymap.set('n', '<leader>gi', vim.lsp.buf.implementation, bufopts("Goto implementation"))
	vim.keymap.set('n', '<leader>gt', vim.lsp.buf.type_definition, bufopts("Goto type definition"))
	vim.keymap.set('n', '<leader>gn', vim.diagnostic.goto_next, bufopts("Goto next issue"))
	vim.keymap.set('n', '<leader>gN', vim.diagnostic.goto_prev, bufopts("Goto prev issue"))
	vim.keymap.set('n', '<leader>gf', vim.lsp.buf.references, bufopts("Show references"))
	vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts("Code action"))
	vim.keymap.set('n', '<leader>cr', vim.lsp.buf.rename, bufopts("Rename"))
	vim.keymap.set('n', '<leader>cf', function() vim.lsp.buf.format { async = true } end, bufopts("Format"))
	vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, bufopts("Get error"))
end

-- Add additional capabilities supported by nvim-cmp
local capabilities = vim.tbl_deep_extend("force",
	vim.lsp.protocol.make_client_capabilities(),
	require('cmp_nvim_lsp').default_capabilities()
)
capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false

local lspconfig = require('lspconfig')

-- Enable some language servers with the additional completion capabilities offered by nvim-cmp
local servers = { 'nixd', 'ocamllsp', 'clangd', 'rust_analyzer', 'pyright', 'tsserver', 'gopls', 'marksman' }
for _, lsp in ipairs(servers) do
	lspconfig[lsp].setup {
		on_attach = on_attach,
		capabilities = capabilities,
	}
end

lspconfig['lua_ls'].setup {
	on_attach = on_attach,
	capabilities = capabilities,
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
				library = vim.api.nvim_get_runtime_file("", true),
				checkThirdParty = false,
			},
			-- Do not send telemetry data containing a randomized but unique identifier
			telemetry = {
				enable = false,
			},
		},
	},
}

-- nvim-cmp

local cmp = require 'cmp'
cmp.setup {
	mapping = cmp.mapping.preset.insert({
		['<C-u>'] = cmp.mapping.scroll_docs( -4),
		['<C-d>'] = cmp.mapping.scroll_docs(4),
		['<C-Space>'] = cmp.mapping.complete(),
		['<Tab>'] = cmp.mapping.confirm {
			behavior = cmp.ConfirmBehavior.Replace,
			select = true,
		},
	}),
	sources = {
		{ name = 'nvim_lsp' },
		{ name = 'luasnip' },
		{ name = 'nvim_lsp_signature_help' },
		{ name = 'path' },
		{ name = 'buffer' },
	},
}

