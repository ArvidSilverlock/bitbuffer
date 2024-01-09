local BASE64_VALUES = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local BASE64_CODE_SIZE = 6 -- 2^6 == 64

-- These make the `tostring` functions much faster, as it doesn't need to re-create the string forms
-- of all the numbers again, just reads if from the lookup tables.
local BINARY_LOOKUP = {}
local BASE64_LOOKUP = {}
local HEX_LOOKUP = {}

do -- Population of the `tobase` formats.
	for i = 0, 255 do
		local binaryValue = table.create(8)
		for j = 7, 0, -1 do
			binaryValue[8 - j] = bit32.extract(i, j, 1)
		end
		local binaryString = table.concat(binaryValue)

		BINARY_LOOKUP[i] = binaryString
		HEX_LOOKUP[i] = string.format("%02x", i)
	end

	-- Convert the `BASE64_VALUES` string into a table.
	for i = 0, 63 do
		BASE64_LOOKUP[i] = BASE64_VALUES:sub(i + 1, i + 1)
	end
end

local FLIP_ENDIAN = {
	[1] = function(value)
		return value
	end,
	[2] = function(value)
		return bit32.bor(bit32.lshift(value, 8), bit32.rshift(value, 8))
	end,
	[3] = function(value)
		return bit32.bor(
			bit32.rshift(bit32.band(value, 0xFF0000), 16),
			bit32.lshift(bit32.band(value, 0x0000FF), 16),
			bit32.band(value, 0x00FF00)
		)
	end,
	[4] = function(value)
		return bit32.bor(
			bit32.rshift(bit32.band(value, 0xFF000000), 24),
			bit32.rshift(bit32.band(value, 0x00FF0000), 8),
			bit32.lshift(bit32.band(value, 0x0000FF00), 8),
			bit32.lshift(bit32.band(value, 0x000000FF), 24)
		)
	end,
}

-- `read` and `write` functions for 8, 16, 24 and 32 bits, 24 bits is custom and uses a secondary
-- buffer to read/write the values using the `writeu32` function.
local U24_BUFFER = buffer.create(4)

local BUFFER_READ = {
	[1] = buffer.readu8,
	[2] = buffer.readu16,
	[3] = function(b: buffer, offset: number)
		buffer.copy(U24_BUFFER, 0, b, offset, 3)
		return buffer.readu32(U24_BUFFER, 0)
	end,
	[4] = buffer.readu32,
}

local BUFFER_WRITE = {
	[1] = buffer.writeu8,
	[2] = buffer.writeu16,
	[3] = function(b: buffer, offset: number, value: number)
		buffer.writeu32(U24_BUFFER, 0, value)
		buffer.copy(b, offset, U24_BUFFER, 0, 3)
	end,
	[4] = buffer.writeu32,
}

-- Any usage of `bit32.lshift` and `bit32.rshift` where the displacement is `3` emulate integer division
-- and multiplication by 8 (2^3, hence the 3), this is done because bitshifting is faster than generic
-- mathmatical operations.
local function toBufferSpace(b: buffer, offset: number, width: number): (number, number, number)
	local byte = bit32.rshift(offset, 3) -- offset * 8
	local bit = bit32.band(offset, 0b111) -- offset % 8

	local remainingBytes = buffer.len(b) - byte
	local byteWidth = bit32.rshift(bit + width + 7, 3) -- math.ceil(( bit + width ) / 8)

	bit = (bit32.lshift(byteWidth, 3) - width) - bit

	return byte, bit, byteWidth, remainingBytes
end

local bitbuffer = {}

function bitbuffer.read(b: buffer, offset: number, width: number): number
	local byte, bit, byteWidth, remainingBytes = toBufferSpace(b, offset, width)
	assert(remainingBytes >= byteWidth, "buffer access out of bounds") -- prevent crashes in --!native mode

	if byteWidth > 4 then -- outside of `bit32`'s functionality
		assert(width <= 48, "`bitbuffer` does not suppoer `width`s greater than 48")

		local value, position = 0, 0

		repeat
			local chunkSize = math.min(width - position, 24) -- When we're on the final read call we can't read a full 3 bytes.
			value += bitbuffer.read(b, offset + position, chunkSize) * bit32.lshift(1, position) -- * 2^position
			position += chunkSize
		until position == width

		return value
	elseif bit == 0 and width == byteWidth then -- Fully aligned to bits 8, 16, 24 and 32, allows for normal functions to be used.
		local read, flip = BUFFER_READ[byteWidth], FLIP_ENDIAN[byteWidth]
		return flip(read(b, byte))
	else -- Confined within one read call.
		local read, flip = BUFFER_READ[byteWidth], FLIP_ENDIAN[byteWidth]
		return bit32.extract(flip(read(b, byte)), bit, width)
	end
end

function bitbuffer.write(b: buffer, offset: number, value: number, width: number)
	local byte, bit, byteWidth, remainingBytes = toBufferSpace(b, offset, width)
	assert(remainingBytes >= byteWidth, "buffer access out of bounds") -- prevent crashes in --!native mode

	if byteWidth > 4 then -- outside of `bit32`'s functionality
		assert(width <= 48, "`bitbuffer` does not suppoer `width`s greater than 48")

		local position = 0
		local chunk

		repeat
			local chunkSize = math.min(width - position, 24) -- When we're on the final read call we can't read a full 3 bytes.

			local mask = bit32.lshift(1, chunkSize) -- 2^chunkSize
			chunk, value = value % mask, value // mask -- effectively rshift `value` by `chunkSize`

			bitbuffer.write(b, offset + position, chunk, chunkSize)
			position += chunkSize
		until position == width
	elseif bit == 0 and width == byteWidth then -- Fully aligned to bits 8, 16, 24 and 32, allows for normal functions to be used.
		local write, flip = BUFFER_WRITE[byteWidth], FLIP_ENDIAN[byteWidth]
		write(b, byte, flip(value))
	else -- Confined within one write call.
		local read, write, flip = BUFFER_READ[byteWidth], BUFFER_WRITE[byteWidth], FLIP_ENDIAN[byteWidth]
		write(b, byte, flip(bit32.replace(flip(read(b, byte)), value, bit, width)))
	end
end

-- A function that automatically constructs `tobase` functions given the lookup of numbers to their
-- string forms, along with some other configuration parameters.
local function tobase(options: {
	prefix: string,
	separator: string,
	paddingCharacters: { string }?,
	characters: { [number]: string },
})
	local prefix, defaultSeparator, paddingCharacters, characters =
		options.prefix, options.separator, options.paddingCharacters, options.characters

	local width = math.log(#characters + 1, 2) -- Calculates how many bits are represented by the lookup table.
	assert(width % 1 == 0, "this lookup table does not represent a whole number of bits")
	assert(
		not paddingCharacters and width % 8 == 0 or paddingCharacters,
		"padding is required for bases that are not byte aligned"
	)

	return function(b: buffer, separator: string?, addPrefix: boolean?): string
		local byteCount = buffer.len(b)
		local bitCount = bit32.lshift(byteCount, 3) -- buffer.len(b) * 8
		local characterCount = math.ceil(bitCount / width)

		local output = table.create(characterCount + (if addPrefix then 1 else 0))
		if addPrefix then
			table.insert(output, prefix)
		end -- Add the prefix if need be.

		-- iterate over each code in the buffer
		local endOffset = (characterCount - 1) * width
		for offset = 0, endOffset, width do
			local byteWidth = math.min(width, bitCount - offset) -- Prevent reading over the end of the buffer.
			local byte = bit32.lshift(bitbuffer.read(b, offset, byteWidth), width - byteWidth) -- `lshift` to account for missing bits if we're at the end.
			table.insert(output, characters[byte])
		end

		local padding = if paddingCharacters then paddingCharacters[byteCount % #paddingCharacters + 1] else ""
		return table.concat(output, separator or defaultSeparator) .. padding
	end
end

bitbuffer.tobinary = tobase({
	characters = BINARY_LOOKUP,
	prefix = "0b",
	separator = "_",
})

bitbuffer.tohex = tobase({
	characters = HEX_LOOKUP,
	prefix = "0x",
	separator = "_",
})

bitbuffer.tohex = tobase({
	characters = BASE64_LOOKUP,
	paddingCharacters = { "", "==", "=" },
	prefix = "",
	separator = "",
})

return bitbuffer
