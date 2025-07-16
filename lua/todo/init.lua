local M = {}

local config = require("todo.config")

function M.setup(opts)
	config.setup(opts)
	local collector = require("todo.collector")
	vim.api.nvim_create_user_command("LoadedTodos", collector.loadedTodos, {})
	vim.api.nvim_create_user_command("CurrentTodos", collector.currentTodos, {})
	vim.api.nvim_create_user_command("ProjectTodos", collector.projectTodos, {})
	vim.api.nvim_create_user_command("ReloadTodo", function()
		package.loaded["todo"] = nil
		require("todo").setup()
	end, {})
end

return M
