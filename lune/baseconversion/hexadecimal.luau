function bitbuffer.tohexadecimal(b: buffer, separator: string?): string
	local separatorLength = if separator then #separator else 1
	local lookupTable = getHexadecimalLookup(separator or "_")

	local str = buffer.tostring(b):gsub(".", lookupTable)
	return str:sub(1, -1 - separatorLength)
end

function bitbuffer.fromhexadecimal(str: string, separator: string?)
	local separatorLength = if separator then #separator else 0

	local codeLength = 2 + separatorLength
	local b = buffer.create((#str + separatorLength) / codeLength)

	local offset = 0
	for index = 1, #str, codeLength do
		local code = str:sub(index, index + 1)
		buffer.writeu8(b, offset, HEXADECIMAL_TO_NUMBER[code])
		offset += 1
	end

	return b
end
