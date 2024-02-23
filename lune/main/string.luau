local READ_STRING = [[--- Used to read a string of length ‘count’ from the buffer at specified offset.
function bitbuffer.writestring(b: buffer, byte: number, bit: number, value: string, count: number?)
	if bit == 0 then
		buffer.writestring(b, byte, value, count)
	else
		local stringLength = count or #value
		local chunkMax = stringLength // 6 * 6

		for stringIndex = 1, chunkMax, 6 do
			local chunk = string.unpack("I6", value, stringIndex)
			bitbuffer.writeu48(b, byte + (stringIndex - 1), bit, chunk)
		end

		byte += chunkMax - 1
		for stringIndex = 1, stringLength - chunkMax do
			local char = value:byte(chunkMax + stringIndex)
			bitbuffer.writeu8(b, byte + stringIndex, bit, char)
		end
	end
end]]

local WRITE_STRING = [[--[=[
	Used to write data from a string into the buffer at a specified offset.

	If an optional ‘count’ is specified, only ‘count’ bytes are taken from the string.

	Count cannot be larger than the string length.
]=]
function bitbuffer.readstring(b: buffer, byte: number, bit: number, count: number): string
	if bit == 0 then
		return buffer.readstring(b, byte, count)
	else
		local output = table.create((count + 5) // 6)
		local chunkMax = count // 6 * 6

		for stringIndex = 1, chunkMax, 6 do
			local chunk = bitbuffer.readu48(b, byte + (stringIndex - 1), bit)
			table.insert(output, string.pack("I6", chunk))
		end

		byte += chunkMax - 1
		for stringIndex = 1, count - chunkMax do
			local chunk = bitbuffer.readu8(b, byte + stringIndex, bit)
			table.insert(output, string.char(chunk))
		end

		return table.concat(output)
	end
end]]

local function create()
	local output = {}
	table.insert(output, WRITE_STRING)
	table.insert(output, READ_STRING)
	return output
end

return create
