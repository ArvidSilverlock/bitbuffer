local function indentString(amount: number, str: string): string
	if str == nil then
		return ""
	elseif str:match("^%s*$") then -- entirely whitespace
		return ""
	end

	local indent = string.rep("\t", amount)
	return indent .. str:gsub("\n", "\n" .. indent):gsub("\n%s+\n", "\n\n")
end

local Snippet = {}
Snippet.__index = Snippet

Snippet.snippets = {}

function Snippet.new(name: string?)
	local self = setmetatable({
		_lines = {},
		_indent = 0,
	}, Snippet)

	if name then
		Snippet.snippets[name] = self
	end

	return self
end

function Snippet.get(name: string)
	return Snippet.snippets[name]
end

function Snippet:Push(...: any)
	for index = 1, select("#", ...) do
		local line = select(index, ...)
		if type(line) == "number" then
			self._indent += line
		elseif type(line) == "table" then
			for _, subLine in line._lines or line do
				table.insert(self._lines, indentString(self._indent, subLine))
			end
		else
			table.insert(self._lines, indentString(self._indent, line))
		end
	end
	return self
end

function Snippet:LuauBlock(name: string, body: string | (...any) -> (), ...: any)
	self:Push(`do -- {name}`, 1)
	if type(body) == "string" then
		self:Push(body)
	else
		body(self, ...)
	end
	self:Push(-1, "end")
	return self
end

function Snippet:ConditionalPush(condition: boolean?, ...: any)
	if condition then
		self:Push(...)
	end
	return self
end

function Snippet:Call(callback: (any, ...any) -> (), ...: any)
	callback(self, ...)
	return self
end

function Snippet:ConditionalCall(condition: boolean?, callback: (any, ...any) -> (), ...: any)
	if condition then
		callback(self, ...)
	end
	return self
end

function Snippet:Break()
	table.insert(self._lines, "")
	return self
end

function Snippet:__tostring(): string
	return table.concat(self._lines, "\n")
end

function Snippet.isSnippet(value: any?): boolean
	return type(value) == "table" and getmetatable(value) == Snippet
end

return Snippet
