
local function find_vault_path()
	local cwd = vim.loop.cwd()
	local path = cwd
	while path ~= "/" do
		if vim.fs.basename(path) == "vault" then
			return path
		end
		path = vim.fs.dirname(path)
	end
	return nil
end

local vault_path = find_vault_path()

if vault_path ~= nil then
	require("obsidian").setup({
		workspaces = {
			{
				name = "vault",
				path = vault_path,
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
end
