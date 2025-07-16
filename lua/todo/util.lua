local M = {}

M.findProjectRoot = function(markers)
	markers = markers or { ".git", "go.mod", "Makefile", "package.json", "pyproject.toml" }

	local root = vim.fs.find(markers, { upward = true, stop = vim.loop.os_homedir() })[1]
	if root then
		return vim.fs.dirname(root)
	end

	-- fallback to current buffer’s dir
	local bufname = vim.api.nvim_buf_get_name(0)
	if bufname ~= "" then
		return vim.fn.fnamemodify(bufname, ":p:h")
	end

	return vim.fn.getcwd()
end

return M
