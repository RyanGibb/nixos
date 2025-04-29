local ls = require('luasnip')
require("luasnip.loaders.from_vscode").lazy_load()
local s = ls.snippet
local f = ls.function_node
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local sn = ls.snippet_node
local d = ls.dynamic_node

local function date_input()
	return os.date('%Y-%m-%d')
end

local function amount_spacing(args)
	local account_length = #args[1][1]
	local amount = args[2][1]
	if amount == '' then
		return ''
	end
	local desired_column = vim.g.ledger_align_at or 50
	local current_column = 2 + account_length + 2 -- 2 spaces after account
	local period_position = amount:find('%.') or (#amount + 1)
	local pre_period_length = period_position - 1
	local total_length = current_column + pre_period_length
	local spaces_needed = desired_column - total_length
	if spaces_needed < 0 then spaces_needed = 1 end
	return string.rep(' ', spaces_needed)
end

local function recursive_accounts()
	return sn(nil, {
		t({ '', '    ' }), i(1, 'Account'), f(amount_spacing, { 1, 2 }),
		c(2, {
			t(''),
			sn(nil, { i(1, '£') })
		}),
		c(3, {
			t(''),
			d(nil, recursive_accounts)
		})
	})
end

ls.add_snippets('all', {
	s('d', {
		f(date_input)
	}),
	s('ledger', {
		i(1, f(date_input)), t(' '), i(2, 'Description'),
		c(3, {
			sn(nil, { t({ '', '    ; ' }), i(1, 'Comment') }),
			t(''),
		}),
		t({ '', '    ' }), i(4, 'Account'), f(amount_spacing, { 4, 5 }),
		c(5, {
			sn(nil, { i(1, '£') }),
			t(''),
		}),
		d(6, recursive_accounts),
		t({ '', '', '' }),
	}),
})
ls.add_snippets('mail', {
	s('attach', {
		t({ '<#part filename=' }),
		i(1, '~/'),
		c(2, {
			sn(nil, { t({ ' description="', }), i(1, ''), t({ '"', }) }),
			t(''),
		}),
		t({ '><#/part>', '' }),
	}),
})


vim.keymap.set({ 'i' }, '<C-k>', function() ls.expand() end, { silent = true; desc = 'Snip complete' })
vim.keymap.set({ 'i', 's' }, '<C-l>', function() ls.jump(1) end, { silent = true; desc = 'Snip next' })
vim.keymap.set({ 'i', 's' }, '<C-h>', function() ls.jump(-1) end, { silent = true; desc = 'Snip prev' })
vim.keymap.set({ 'i', 's' }, '<C-j>', function()
	if ls.choice_active() then
		ls.change_choice(1)
	end
end, { silent = true; desc = 'Snip choice'  })
