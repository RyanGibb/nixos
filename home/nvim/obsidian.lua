require("obsidian").setup({
	workspaces = {
		{
			name = "vault",
			path = "~/vault",
		},
	},
	completion = {
		nvim_cmp = true,
		min_chars = 2,
	},
	mappings = {
		-- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
		["gf"] = {
			action = function()
				return require("obsidian").util.gf_passthrough()
			end,
			opts = { noremap = false, expr = true, buffer = true },
		},
		-- Toggle check-boxes.
		["<leader>ch"] = {
			action = function()
				return require("obsidian").util.toggle_checkbox()
			end,
			opts = { buffer = true },
		},
		-- Smart action depending on context, either follow link or toggle checkbox.
		["<cr>"] = {
			action = function()
				return require("obsidian").util.smart_action()
			end,
			opts = { buffer = true, expr = true },
		}
	},
	ui = {
		enable = false,
	},
	disable_frontmatter = true,
	wiki_link_func = "use_path_only",
})
