require('telescope').load_extension('fzf')
require("telescope").load_extension("undo")
require("telescope").load_extension("file_browser")
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

vim.keymap.set('n', '<leader>ff', require('telescope.builtin').find_files, { desc = 'Find files' })
vim.keymap.set('n', '<leader>fg', require('telescope.builtin').live_grep, { desc = 'Find grep' })
vim.keymap.set('n', '<leader>fv', require('telescope.builtin').git_files, { desc = 'Find version control' })
vim.keymap.set('n', '<leader>fb', function() require('telescope.builtin').buffers({ sort_mru = true }) end, { desc = 'Find buffer' })
vim.keymap.set('n', '<leader>fh', require('telescope.builtin').help_tags, { desc = 'Find help' })
vim.keymap.set('n', '<leader>fq', require('telescope.builtin').command_history, { desc = 'Find command' })
vim.keymap.set('n', '<leader>fs', require('telescope.builtin').search_history, { desc = 'Find search' })
vim.keymap.set('n', '<leader>fj', require('telescope.builtin').jumplist, { desc = 'Find jumplist' })
vim.keymap.set('n', '<leader>fm', require('telescope.builtin').marks, { desc = 'Find marks' })
vim.keymap.set('n', '<leader>fx', require('telescope.builtin').diagnostics, { desc = 'Find diagnostics' })
vim.keymap.set('n', '<leader>fy', require('telescope.builtin').registers, { desc = 'Find registers' })
vim.keymap.set('v', '<leader>fy', require('telescope.builtin').registers, { desc = 'Find registers' })
vim.keymap.set('n', '<leader>fr', require('telescope.builtin').lsp_references, { desc = 'Find references' })
vim.keymap.set('n', '<leader>fS', require('telescope.builtin').lsp_document_symbols, { desc = 'Find LSP symbols' })
vim.keymap.set('n', '<leader>fc', require('telescope.builtin').lsp_incoming_calls, { desc = 'Find LSP incoming calls' })
vim.keymap.set('n', '<leader>fo', require('telescope.builtin').lsp_outgoing_calls, { desc = 'Find LSP outgoing calls' })
vim.keymap.set('n', '<leader>fi', require('telescope.builtin').lsp_implementations, { desc = 'Find LSP implementations' })
vim.keymap.set('n', '<leader>fu', require('telescope').extensions.undo.undo, { desc = 'Find undo' })
vim.keymap.set('n', '<leader>fd', function() require('telescope').extensions.file_browser.file_browser({ path = '%:p:h', select_buffer = true }) end, { desc = 'Find directory' })
