local function flipu16(value: number): number
	return (value // 0x100) -- FF00 -> 00FF
		+ (value % 0x100 * 0x100) -- 00FF -> FF00
end

--[=[
	@function tobase64
	@within bitbuffer

	Returns the buffer data as a base64 encoded string.

	@param b buffer
	@return string
]=]
function bitbuffer.tobase64(b: buffer): string
	local bufferLength = buffer_len(b)
	local bitCount = bufferLength * 8

	local paddingLength = 2 - (bufferLength - 1) % (2 + 1)
	local characterCount = math.ceil(bitCount / 6)

	local endOffset = (characterCount - 1) * 6
	local overhang = bitCount - endOffset

	local output = buffer_create(characterCount + paddingLength)
	local outputIndex = 0

	for offset = 0, endOffset - overhang, 6 do
		local byte, bit = offset // 8, offset % 8
		local byteWidth = (bit + 13) // 8
		bit = (byteWidth * 8 - 6) - bit

		local focus = if byteWidth == 1 then readu8(b, byte) else flipu16(readu16(b, byte))
		local code = bit32_extract(focus, bit, 6)

		writeu8(output, outputIndex, readu8(NUMBER_TO_BASE64, code))
		outputIndex += 1
	end

	if overhang > 0 then
		local byte, bit = endOffset // 8, (8 - overhang) - endOffset % 8

		local focus = readu8(b, byte)
		local code = bit32.lshift(bit32_extract(focus, bit, overhang), 6 - overhang)

		writeu8(output, outputIndex, readu8(NUMBER_TO_BASE64, code))
	end

	buffer_fill(output, characterCount, 61, paddingLength) -- '='
	return buffer_tostring(output)
end

--[=[
	@function frombase64
	@within bitbuffer

	Creates a buffer initialized to the contents of the base64 encoded string.

	@param str string
	@return buffer
]=]
function bitbuffer.frombase64(str: string)
	local paddingStart, paddingEnd = string.find(str, "=*$")
	local padding = (paddingEnd :: any) - (paddingStart :: any) + 1

	local codeCount = #str - padding
	local bitCount = (codeCount * 6) - (padding * 2)

	local endOffset = bitCount // 6 * 6
	local overhang = bitCount - endOffset

	local output = buffer_create(bitCount // 8)

	local inputIndex = 1
	for outputOffset = 0, endOffset - 6, 6 do
		local byte, bit = outputOffset // 8, outputOffset % 8
		local byteWidth = (bit + 13) // 8
		bit = (byteWidth * 8 - 6) - bit

		local code = BASE64_TO_NUMBER[str:byte(inputIndex)]
		if byteWidth == 2 then
			writeu16(output, byte, flipu16(bit32_replace(flipu16(readu16(output, byte)), code, bit, 6)))
		else
			writeu8(output, byte, bit32_replace(readu8(output, byte), code, bit, 6))
		end

		inputIndex += 1
	end

	if overhang > 0 then
		local byte, bit = endOffset // 8, (8 - overhang) - endOffset % 8
		local code = bit32.rshift(BASE64_TO_NUMBER[str:byte(inputIndex)], 6 - overhang)

		writeu8(output, byte, bit32_replace(readu8(output, byte), code, bit, overhang))
	end

	return output
end
