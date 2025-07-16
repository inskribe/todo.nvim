local M = {}
local actionState = require("telescope.actions.state")
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local config = require("todo.config")

local ts = vim.treesitter

---@class TodoResult
---@field filename string
---@field lnum integer
---@field text string

---Returns the current buffers todos if any
---@return TodoResult[]|nil
function M.getCurrentBufferTodos()
	local buffIndex = vim.api.nvim_get_current_buf()
	local fileType = vim.bo[buffIndex].filetype
	local language = vim.treesitter.language.get_lang(fileType)

	if not language then
		-- TODO::Debugging
		-- record file name to add to something like "Unsearchable Buffers"
		return nil
	end

	local todos = M.searchTree(buffIndex, language, { error = false })
	if not todos then
		return nil
	end

	return todos
end

---Returns the todos for all loaded buffers if any.
---@return TodoResult[]|nil
function M.getLoadedBuffersTodos()
	---@type TodoResult[]
	local results = {}
	for _, bufferIndex in ipairs(vim.api.nvim_list_bufs()) do
		if not vim.api.nvim_buf_is_loaded(bufferIndex) then
			goto continue
		end

		local fileType = vim.bo[bufferIndex].filetype
		local language = vim.treesitter.language.get_lang(fileType)

		if not language then
			-- TODO::Debugging
			-- record file name to add to something like "Unsearchable Buffers"
			goto continue
		end

		local todos = M.searchTree(bufferIndex, language, { error = false })
		if not todos then
			goto continue
		end

		table.move(todos, 1, #todos, #results + 1, results)

		::continue:: -- Buffer list break
	end
	return results
end

--- Searches the syntax tree for the buffer at bufferIndex
--- returning a TodoResult for each matched comment node.
---@param bufferIndex integer
---@param language string
---@param opts table|nil
---@return TodoResult[]|nil
function M.searchTree(bufferIndex, language, opts)
	local parser, _ = vim.treesitter.get_parser(bufferIndex, language, opts)
	if parser == nil then
		return nil
	end

	local tree = parser:parse()[1]
	local root = tree:root()

	local query = vim.treesitter.query.parse(
		language,
		[[
          (comment) @comment
        ]]
	)

	--- @type TodoResult[]
	local results = {}
	for _, node in query:iter_captures(root, bufferIndex, 0, -1) do
		local text = ts.get_node_text(node, bufferIndex)
		local row, _, _, _ = node:range()

		if text:match("TODO") == nil then
			goto continue
		end
		---@type TodoResult
		local todo = {
			filename = vim.api.nvim_buf_get_name(bufferIndex),
			lnum = row + 1,
			text = M.ParseTodo(text),
		}

		table.insert(results, todo)
		::continue:: -- Query itter break
	end
	return results
end

function M.ParseTodo(todo)
	--TODO::Support
	--Extend parser support for other language
	return require("todo.parsers.slashStar").ParseSlashStar(todo)
end

--- Creates and shows a telescope picker to
--- display colleceted todos.
---@param getTodos fun(): TodoResult[]
local function buildPicker(getTodos)
	assert(getTodos ~= nil, "expected a function that reutrns a table of strings, recived nil")
	local todos = getTodos()

	local themes = require("telescope.themes")

	pickers
		.new(themes.get_ivy({}), {
			prompt_title = "TODOs",
			finder = finders.new_table({
				results = todos,
				entry_maker = function(entry)
					return {
						value = entry,
						display = string.format(
							"%s:%d: %s",
							vim.fn.fnamemodify(entry.filename, ":."),
							entry.lnum,
							entry.text
						),
						ordinal = entry.text,
						filename = entry.filename,
						lnum = entry.lnum,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = actionState.get_selected_entry()
					actions.close(prompt_bufnr)

					vim.cmd("edit " .. vim.fn.fnameescape(selection.filename))
					vim.fn.cursor(selection.lnum, 1)
					vim.cmd("normal! zz")
				end)
				return true
			end,
		})
		:find()
end

--- Returns the contents of the file at path
---@param path string
---@return any|nil
local function readFile(path)
	if path == "" then
		return nil
	end

	local file = io.open(path, "r")
	if not file then
		return nil
	end

	local content = file:read("*a")
	file:close()

	return content
end

local function findSourceFiles(root)
	return vim.fn.systemlist("cd " .. vim.fn.shellescape(root) .. "&& fd --type f --extension go --extension lua")
end

function M.getProjectTodos()
	local root = require("todo.util").findProjectRoot(config.options.root_markers)
	local files = findSourceFiles(root)
	local results = {}

	for _, file in ipairs(files) do
		local todos = M.extractTodosFromFile(file)
		if not todos then
			goto continue
		end

		table.move(todos, 1, #todos, #results + 1, results)
		::continue::
	end
	return results
end

function M.extractTodosFromFile(path)
	local parser = require("todo.parsers.slashStar")
	local content = readFile(path)
	if not content then
		return nil
	end

	local todos = {}
	local inBlock = false
	local blockContent = {}
	local seperatedLines = vim.split(content, "\n")

	for lnum, line in ipairs(seperatedLines) do
		-- Block comment start
		if line:match("^%s*/%*") then
			inBlock = true
			blockContent = { line }
		elseif inBlock then
			table.insert(blockContent, line)
			-- Block comment end
			if line:match("%*/") then
				inBlock = false
				local block = table.concat(blockContent, "\n")
				if block:match("TODO::") then
					table.insert(todos, {
						filename = path,
						lnum = lnum - #blockContent + 1,
						text = parser.ParseSlashStar(block),
					})
				end
			end
		else
			-- Single-line comment
			local todoLine = line:match("^%s*[%-%/%#]+%s*TODO::.*")
			if todoLine then
				table.insert(todos, {
					filename = path,
					lnum = lnum,
					text = parser.ParseSlashStar(todoLine),
				})
			end
		end
	end

	return todos
end

M.loadedTodos = function()
	buildPicker(M.getLoadedBuffersTodos)
end
M.currentTodos = function()
	buildPicker(M.getCurrentBufferTodos)
end

M.projectTodos = function()
	buildPicker(M.getProjectTodos)
end
return M
