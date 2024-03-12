local READ_STRING = [[--[=[
	Used to write data from a string into the buffer at a specified offset.

	If an optional ‘count’ is specified, only ‘count’ bytes are taken from the string.

	Count cannot be larger than the string length.
]=]
function bitbuffer.writestring(b: buffer, byte: number, bit: number, value: string, count: number?)
	if bit == 0 then
		buffer.writestring(b, byte, value, count)
	else
		local input = buffer.fromstring(value)
		bitbuffer.copy(b, byte, bit, input, 0, 0, ( count or #value ) * 8)
	end
end]]

local WRITE_STRING = [[--- Used to read a string of length ‘count’ from the buffer at specified offset.
function bitbuffer.readstring(b: buffer, byte: number, bit: number, count: number): string
	if bit == 0 then
		return buffer.readstring(b, byte, count)
	else
		local output = buffer.create(count)
		bitbuffer.copy(output, 0, 0, b, byte, bit, count * 8)
		return buffer.tostring(output)
	end
end]]

return function(luau, typescript)
	-- stylua: ignore start
	luau:Push(
		WRITE_STRING,
		"",
		READ_STRING
	)

	typescript:Push(
		"writestring: write<string>;",
		"readstring: read<string>;",
		""
	)
	-- stylua: ignore end
end
