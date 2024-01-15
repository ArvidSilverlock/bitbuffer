local function merge<T>(...: { T }): { T }
	local count = select("#", ...)
	assert(count >= 2, "there must be two or more tables to merge")

	local initial = select(1, ...)
	local output = table.clone(initial)

	for i = 2, count do
		local value = select(i, ...)
		table.move(value, 1, #value, #output + 1, output)
	end

	return output
end

local function collapse<T>(t: { { T } }): { T }
	return merge(table.unpack(t))
end

local function cull<K, V>(input: { [K]: V }, predicate: (value: V, key: K) -> boolean?): { [K]: V }
	local output = table.clone(input)

	for key, value in input do
		if not predicate(value, key) then
			output[key] = nil
		end
	end

	return output
end

local function cullDuplicates<V>(input: { V }): { V }
	local output = {}
	local found = {}

	for _, value in input do
		if not found[value] then
			table.insert(output, value)
			found[value] = true
		end
	end

	return output
end

local function map<K, V>(input: { [K]: V }, transformer: (value: V, key: K) -> boolean?): { [K]: V }
	local output = {}

	for key, value in input do
		output[key] = transformer(value, key)
	end

	return output
end

local function compareTests(a: ModuleScript, b: ModuleScript): boolean
	local numberA, numberB = a.Name:match("(%d+)%.spec$"), b.Name:match("(%d+)%.spec$")
	return if numberA and numberB
		then tonumber(numberA) < tonumber(numberB)
		elseif numberA and not numberB then false
		elseif numberB and not numberA then true
		else a.Name < b.Name
end

local Editors = script.Editors

-- Really ugly, but sorts the tests in the correct order
-- stylua: ignore
return cullDuplicates(cull(collapse(map(
	{
		{
			script["littleEndian.spec"],
			script["bigEndian.spec"],
			script["tobase.spec"],
			script["frombase.spec"]
		},
		Editors.UInt,
		Editors.Int,
		Editors.Float,
		Editors
	},
	function(value) -- map
		if typeof(value) == "Instance" and value:IsA("Folder") then
			local sortedChildren = value:GetChildren()
			table.sort(sortedChildren, compareTests)
			return sortedChildren
		else
			return value
		end
	end)),
	function(value) -- cull
		return value:IsA("ModuleScript")
	end)
)