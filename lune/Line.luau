local Line = {}
Line.__index = Line

function Line.new(...: string)
	local text = setmetatable({}, Line)
	if select("#", ...) > 0 then
		text:Push(...)
	end

	return text
end

function Line:Push(...: string)
	for i = 1, select("#", ...) do
		local value = tostring(select(i, ...))
		table.insert(self, tostring(value))
	end
	return self
end

function Line:ConditionalPush(condition: boolean?, ...: string)
	if condition then
		self:Push(...)
	end
	return self
end

function Line:Indent(amount: number?)
	local indent = string.rep("\t", amount or 1)

	self[1] = indent .. self[1]
	for i, line in self do
		self[i] = line:gsub("\n", "\n" .. indent)
	end

	return self
end

function Line:Insert(index: number, ...: string)
	for i = 1, select("#", ...) do
		local value = tostring(select(i, ...))
		table.insert(self, index + (i - 1), value)
	end
	return self
end

function Line:__tostring(): string
	return table.concat(self, "")
end

return Line
