vim.cmd [[colorscheme palenight]]
vim.api.nvim_command('hi Normal ctermbg=NONE')

vim.g['airline#extensions#tabline#enabled'] = 1
vim.g.airline_theme = 'bubblegum'
vim.g['airline#extensions#tabline#buffer_nr_show'] = 1

vim.o.mouse = 'a'
vim.o.clipboard = 'unnamedplus'
vim.o.hidden = true
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.spelllang = 'en'
vim.o.spellfile = os.getenv('HOME')..'/.config/vim/spell.en.utf-8.add'
vim.o.conceallevel = 1

vim.g.auto_save_events = {"InsertLeave", "TextChanged"}
vim.g.auto_save_silent = 0

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

vim.api.nvim_create_autocmd('TermOpen', {
    pattern = '*',
    command = 'startinsert',
})

vim.api.nvim_set_keymap('n', 'ZA', ':cquit<Enter>', {noremap = true, silent = true})

vim.opt_local.spell = true
vim.opt_local.spelllang = 'en_gb'

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
})
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

