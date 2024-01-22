require('obsidian').setup({
    dir = "~/vault",
	note_id_func = function(title)
		return tostring(os.date("%Y-%m-%d")) .. " " .. title
	end,
	disable_frontmatter = true,
	attachments = {
		img_folder = "",
	},
})
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
