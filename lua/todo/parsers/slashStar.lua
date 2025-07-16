local M = {}

---Transforms "/*" stlye sytax into a readable todo
---@param text string
---@return string
function M.ParseSlashStar(text)
	if text == "" then
		return ""
	end

	text = M.RemoveOutterSyntax(text)
	text = M.StripStars(text)
	text = M.RemoveNewLine(text)
	text = M.RemoveTodoPrefix(text)
	text = vim.trim(text)

	return text
end

--- Strips bounding language comment syntax.
---@param text string
---@return string
function M.RemoveOutterSyntax(text)
	text = string.gsub(text, "/%*", "")
	text = string.gsub(text, "%*/", "")
	text = string.gsub(text, "//", "")
	return text
end

--- Replaces all new line chars with a space
--- Telescope will represent "\n" charaters as "|"
---@param text any
---@return string
function M.RemoveNewLine(text)
	local lines = vim.split(text, "\n", { plain = true })
	for i, line in ipairs(lines) do
		lines[i] = vim.trim(line)
	end
	return table.concat(lines, " ")
end

--- Removes any asterisk from the todo
--- Note:
---   Will preserve *Reference style syntax.
---@param text string
---@return string
function M.StripStars(text)
	-- return string.gsub(text, "%s*%*%s*", " ")
	local lines = vim.split(text, "\n", { plain = true })
	for i, line in ipairs(lines) do
		-- only strip leading star with optional space after it
		lines[i] = line:gsub("^%s*%*%s?", "")
	end
	return table.concat(lines, "\n")
end

--- Removes the "TODO::" prefix
--- returning the <category>:: <comment>
--- Note:
---   If the text does not contain a category the
---   <category> will be replaced with Missing category.
---   This allows the user not to use categories but still allow
---   for fuzzy seaching of non category todos.
---@param text string
---@return string
function M.RemoveTodoPrefix(text)
	local result = ""

	local category, msg = text:match("^%s*[Tt][Oo][Dd][Oo]::(%S+)%s+(.*)")
	if category and msg then
		result = category .. ":: " .. msg
	end

	-- Case::No category
	-- "TODO:: something" or just "TODO::"
	result, _ = text:gsub("^[Tt][Oo][Dd][Oo]%s*::%s*", "Missing category::", 1)

	return result
end
return M
