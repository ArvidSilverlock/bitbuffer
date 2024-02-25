local Line = require("./Line.luau")

local Snippet = {}
Snippet.__index = Snippet

function Snippet.new(...)
	local snippet = setmetatable({}, Snippet)
	if select("#", ...) > 0 then
		snippet:Push(...)
	end

	return snippet
end

function Snippet:Push(...: string)
	local line = Line.new(...)
	table.insert(self, line)
	return line
end

function Snippet:ConditionalPush(condition: boolean?, ...: string)
	if condition then
		self:Push(...)
	end
	return self
end

function Snippet:Insert(index: number, ...: string)
	local line = Line.new(...)
	table.insert(self, index, line)
	return line
end

function Snippet:Merge(other)
	for _, line in other do
		table.insert(self, line)
	end
	return self
end

function Snippet:Line(index: number?)
	return self[index or #self]
end

function Snippet:Indent(amount: number?)
	for _, line in self do
		line:Indent(amount)
	end
	return self
end

function Snippet:Clear()
	table.clear(self)
	return self
end

function Snippet:__tostring(): string
	local lines = {}
	for _, line in self do
		table.insert(lines, tostring(line))
	end
	return table.concat(lines, "\n")
end

return Snippet
