local function cull<T>(input: { T }, predicate: (value: T) -> boolean?): { T }
	local output = {}

	for _, value in input do
		if predicate(value) then
			table.insert(output, value)
		end
	end

	return output
end

return cull(script:GetDescendants(), function(value)
	return value:IsA("ModuleScript")
end)
