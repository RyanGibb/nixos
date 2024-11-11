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
