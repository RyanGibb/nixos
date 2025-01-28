require('gruvbox').setup {
	terminal_colors = false,
	transparent_mode = true,
}
vim.cmd "colorscheme gruvbox"

vim.api.nvim_set_hl(0, "NormalFloat", { fg = require('gruvbox').palette.light1, bg = require('gruvbox').palette.dark1 })

vim.o.mouse = 'a'
vim.o.mousemodel = 'extend'

vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.bo.autoindent = true
vim.bo.smartindent = true

vim.o.fixendofline = false

vim.o.conceallevel = 0
vim.o.concealcursor = 'n'
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

vim.keymap.set('n', '<leader>fs', ':w<CR>', { desc = 'Write file' })
vim.keymap.set('n', '<leader>qq', ':qa<CR>', { desc = 'Quit all' })

vim.keymap.set('n', 'ZA', ':cquit<Enter>', { desc = 'Quit and fail' })

vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')

vim.keymap.set('n', '<leader>id', [[<Cmd>lua vim.api.nvim_put({vim.fn.strftime('%Y-%m-%d')}, 'c', true, true)<CR>]],
	{ desc = 'insert date' })

vim.keymap.set('n', '!', ':term ', { desc = 'terminal' })

vim.keymap.set('n', '<leader>gg', ':Neogit<CR>', { desc = 'Neogit' })

vim.keymap.set('n', '<leader>om', ':make<Enter>', { desc = 'Make' })

vim.keymap.set('n', '<leader>w', '<C-w>', { desc = 'Window commands' })

-- go though spelling mistakes
vim.keymap.set('n', '<C-s>', ']s1z=', { desc = 'correct next spelling mistake' })

vim.keymap.set('v', '<C-J>', ":m '>+1<CR>gv=gv", { desc = 'move up' })
vim.keymap.set('v', '<C-K>', ":m '<-2<CR>gv=gv", { desc = 'move down' })

vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

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

vim.keymap.set('n', '<leader>bn', ':bnext<CR>')
vim.keymap.set('n', '<leader>bp', ':bprevious<CR>')
vim.keymap.set('n', '<leader>bd', ':bdelete<CR>')

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

-- vim.api.nvim_create_autocmd('VimLeave', {
-- 	pattern = '*',
-- 	callback = function() save_session({ args = '' }) end,
-- })

vim.api.nvim_create_user_command('SaveSession', save_session, { nargs = '?', complete = session_completion })
vim.api.nvim_create_user_command('LoadSession', load_session, { nargs = '?', complete = session_completion })

vim.keymap.set('n', '<leader>qs', ':SaveSession<CR>', { desc = 'Save session' })
vim.keymap.set('n', '<leader>ql', ':LoadSession<CR>', { desc = 'Load session' })

-- free real-estate
-- <leader>n
-- <leader>;
-- <leader>e
-- <leader>v
-- <leader>l
-- <leader>j
-- <leader>k
-- <leader>z

vim.cmd([[
augroup RememberView
  autocmd!
  autocmd BufWinLeave * let b:win_view = winsaveview()
  autocmd BufWinEnter * if exists('b:win_view') | call winrestview(b:win_view) | endif
augroup END
]])
