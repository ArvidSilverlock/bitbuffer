local getLookup = baseLookupGenerator(CHARACTER_TO_HEXADECIMAL)

--[=[
	@function tobinary
	@within bitbuffer

	Returns the buffer data as a hexadecimal string, mainly useful for debugging.

	@param b buffer
	@param separator string -- the separator characters to use between bytes

	@return string
]=]
function bitbuffer.tohexadecimal(b: buffer, separator: string?): string
	local separatorLength = if separator then #separator else 0
	local lookupTable = getLookup(separator or "")

	local str = buffer_tostring(b):gsub(".", lookupTable)
	return str:sub(1, -1 - separatorLength)
end

--[=[
	@function fromhexadecimal
	@within bitbuffer

	Creates a buffer initialized to the contents of the hexadecimal string.

	@param str string
	@param separator string -- the separator characters to use between bytes

	@return buffer
]=]
function bitbuffer.fromhexadecimal(str: string, separator: string?)
	local separatorLength = if separator then #separator else 0

	local codeLength = 2 + separatorLength
	local b = buffer_create((#str + separatorLength) / codeLength)

	local offset = 0
	for index = 1, #str, codeLength do
		local code = str:sub(index, index + 1)
		writeu8(b, offset, HEXADECIMAL_TO_NUMBER[code])
		offset += 1
	end

	return b
end
