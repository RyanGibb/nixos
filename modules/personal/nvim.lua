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
