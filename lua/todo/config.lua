local M = {}

M.options = {
	root_markers = { ".git" },
}

function M.setup(user_opts)
	M.options = vim.tbl_deep_extend("force", M.options, user_opts or {})
end

return M
