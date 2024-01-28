function bitbuffer.tobinary(b: buffer, separator: string?): string
	local separatorLength = if separator then #separator else 1
	local lookupTable = getBinaryLookup(separator or "_")

	local str = buffer.tostring(b):gsub(".", lookupTable)
	return str:sub(1, -1 - separatorLength)
end

function bitbuffer.frombinary(str: string, separator: string?)
	local separatorLength = if separator then #separator else 0

	local codeLength = 8 + separatorLength
	local b = buffer.create((#str + separatorLength) / codeLength)

	local offset = 0
	for index = 1, #str, codeLength do
		local code = str:sub(index, index + 7)
		buffer.writeu8(b, offset, BINARY_TO_NUMBER[code])
		offset += 1
	end

	return b
end
