-- TODO
-- stdout
-- args

local dap = require('dap')
dap.adapters.ocamlearlybird = {
	type = 'executable',
	command = 'ocamlearlybird',
	args = { 'debug' },
	cwd = "${workspaceFolder}",
}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

dap.configurations.ocaml = {
	{
		name = 'OCaml',
		type = 'ocamlearlybird',
		request = 'launch',
		-- https://github.com/hackwaly/ocamlearlybird/issues/75
		arguments = function()
			return vim.split(vim.fn.input('Arguments: '), " ", { trimempty = true })
		end,
		cwd = vim.fn.getcwd(),
		program = function()
			return coroutine.create(function(coro)
				local opts = {}
				pickers
				.new(opts, {
					prompt_title = "Path to executable",
					finder = finders.new_oneshot_job({ "fd", "--hidden", "--no-ignore", "--type", "x" }, {}),
					sorter = conf.generic_sorter(opts),
					attach_mappings = function(buffer_number)
						actions.select_default:replace(function()
							actions.close(buffer_number)
							coroutine.resume(coro, action_state.get_selected_entry()[1])
						end)
						return true
					end,
				})
				:find()
			end)
		end,
	},
}

vim.keymap.set('n', '<leader>;c', function() require('dap').continue() end, { desc = 'DAP continue' })
vim.keymap.set('n', '<leader>;s', function() require('dap').step_over() end, { desc = 'DAP step over' })
vim.keymap.set('n', '<leader>;i', function() require('dap').step_into() end, { desc = 'DAP step into' })
vim.keymap.set('n', '<leader>;o', function() require('dap').step_out() end, { desc = 'DAP step out' })
vim.keymap.set('n', '<leader>;b', function() require('dap').toggle_breakpoint() end, { desc = 'DAP breakpoint' })
vim.keymap.set('n', '<leader>;m',
	function() require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end,
	{ desc = 'DAP breakpoint message' })
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
vim.keymap.set('n', '<leader>;t', function() require('dap').terminate() end, { desc = 'DAP terminate' })
