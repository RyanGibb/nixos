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
