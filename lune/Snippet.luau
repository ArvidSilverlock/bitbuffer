local function indentString(str: string, amount: number): string
	if str:match("^%s*$") then
		return ""
	end -- Omit lines that are entirely whitespace

	local indent = string.rep("\t", amount)
	return indent .. str:gsub("\n", "\n" .. indent)
end

local function lineToString(indent: number, ...: any): string
	local count = select("#", ...)
	local output = table.create(count)
	for i = 1, count do
		local value = tostring(select(i, ...))
		table.insert(output, tostring(value))
	end

	return indentString(table.concat(output, ""), indent)
end

local Snippet = {}
Snippet.__index = Snippet

function Snippet.new(...: any)
	return setmetatable({
		_lines = {
			if select("#", ...) > 0 then lineToString(0, ...) else nil,
		},
		_indent = 0,
	}, Snippet)
end

function Snippet:Push(...: any)
	table.insert(self._lines, lineToString(self._indent, ...))
	return self
end

function Snippet:ConditionalPush(condition: boolean?, ...: any)
	if condition then
		table.insert(self._lines, lineToString(self._indent, ...))
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

function Snippet:Block(name: string, callback: (...any) -> (), ...)
	self:BlockStart("do -- ", name)
	callback(self, ...)
	self:BlockEnd()
	self:Push("")
	return self
end

function Snippet:BlockStart(...: any)
	table.insert(self._lines, lineToString(self._indent, ...))
	self:Indent(1)
	return self
end

function Snippet:BlockMiddle(...: any)
	self:Indent(-1)
	table.insert(self._lines, lineToString(self._indent, ...))
	self:Indent(1)
	return self
end

function Snippet:BlockEnd(...: any)
	self:Indent(-1)
	local str = if select("#", ...) == 0 then indentString("end", self._indent) else lineToString(self._indent, ...)
	table.insert(self._lines, str)
	return self
end

function Snippet:Insert(index: number?, ...: string)
	table.insert(self._lines, index, lineToString(self._indent, ...))
	return self
end

function Snippet:Merge(other)
	for _, line in other._lines do
		table.insert(self._lines, indentString(line, self._indent))
	end
	return self
end

function Snippet:Indent(amount: number?)
	self._indent += amount or 1
	return self
end

function Snippet:Clear()
	table.clear(self._lines)
	self._indent = 0
	return self
end

function Snippet:__tostring(): string
	return table.concat(self._lines, "\n")
end

return Snippet
