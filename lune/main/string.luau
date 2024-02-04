local READ_STRING = [[function bitbuffer.writestring(b: buffer, offset: number, value: string, count: number?)
	if offset % 8 == 0 then
		buffer.writestring(b, offset // 8, value, count)
	else
		local stringLength = count or #value
		local chunkMax = stringLength // 6 * 6

		for stringIndex = 1, chunkMax, 6 do
			local chunk = string.unpack("I6", value, stringIndex)
			bitbuffer.writeu48(b, offset + (stringIndex - 1) * 8, chunk)
		end

		local overflowStart = offset + (chunkMax - 1) * 8
		for stringIndex = 1, stringLength - chunkMax do
			local byte = value:byte(chunkMax + stringIndex)
			bitbuffer.writeu8(b, overflowStart + stringIndex * 8, byte)
		end
	end
end]]

local WRITE_STRING = [[function bitbuffer.readstring(b: buffer, offset: number, count: number): string
	if offset % 8 == 0 then
		return buffer.readstring(b, offset // 8, count)
	else
		local output = table.create((count + 5) // 6)
		local chunkMax = count // 6 * 6

		for stringIndex = 1, chunkMax, 6 do
			local chunk = bitbuffer.readu48(b, offset + (stringIndex - 1) * 8)
			table.insert(output, string.pack("I6", chunk))
		end

		local overflowStart = offset + (chunkMax - 1) * 8
		for stringIndex = 1, count - chunkMax do
			local chunk = bitbuffer.readu8(b, overflowStart + stringIndex * 8)
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
