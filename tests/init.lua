local function cull<K, V>(input: { [K]: V }, predicate: (value: V, key: K) -> boolean?): { [K]: V }
	local output = table.clone(input)

	for key, value in input do
		if not predicate(value, key) then
			output[key] = nil
		end
	end

	return output
end

return cull(script:GetDescendants(), function(value)
	return value:IsA("ModuleScript")
end)
