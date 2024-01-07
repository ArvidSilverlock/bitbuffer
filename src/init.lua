--!native
--!optimize 2

local BASE64_VALUES = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- These make the `tostring` functions much faster, as it doesn't need to re-create the string forms
-- of all the numbers again, just reads if from the lookup tables.
local BINARY_LOOKUP = {}
local BASE64_LOOKUP = {}
local HEX_LOOKUP = {}

do -- Population of the `tobase` formats.
	for i = 0, 255 do
		local binaryValue = table.create(8)
		for j = 0, 7 do
			binaryValue[j + 1] = bit32.extract(i, j, 1)
		end

		BINARY_LOOKUP[i] = table.concat(binaryValue)
		HEX_LOOKUP[i] = string.format("%02x", i)
	end

	for i = 0, 63 do
		BASE64_LOOKUP[i] = BASE64_VALUES:sub(i + 1, i + 1)
	end
end

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
	local byteWidth = bit32.rshift(bit + width + 7, 3) -- math.ceil(( bit + width ) // 8)

	return byte, bit, byteWidth, remainingBytes
end

local bitbuffer = {}

function bitbuffer.read(b: buffer, offset: number, width: number): number
	local byte, bit, byteWidth, remainingBytes = toBufferSpace(b, offset, width)
	assert(remainingBytes >= byteWidth, "buffer access out of bounds") -- prevent crashes in --!native mode

	if byteWidth > 4 then -- outside of `bit32`'s functionality
		-- `chunkSize` is initialised as this to align the rest of calls to bytes, otherwise it is likely that
		-- a stack overflow occurs if it's not already byte aligned, this is because reading an unaligned 32 bit
		-- integer needs to read 5 bytes of data rather than just 4.
		local value, position, chunkSize = 0, 0, 8 - bit

		-- This effectively iterates over all the groups of 32 bits, but clamps 32 to how many bits are left.
		repeat
			-- bit32.lshift(1, position) is equivalent to 2^position
			value += bitbuffer.read(b, offset + position, chunkSize) * bit32.lshift(1, position)
			position += chunkSize

			chunkSize = math.min(width - position, 32) -- When we're on the final read call we can't read a full 4 bytes.
		until position == width

		return value
	elseif bit == 0 and width == byteWidth then -- Fully aligned to bits 8, 16, 24 and 32, allows for normal functions to be used.
		return BUFFER_READ[byteWidth](b, byte)
	else -- Confined within one read call.
		return bit32.extract(BUFFER_READ[byteWidth](b, byte), bit, width)
	end
end

function bitbuffer.write(b: buffer, offset: number, value: number, width: number)
	local byte, bit, byteWidth, remainingBytes = toBufferSpace(b, offset, width)
	assert(remainingBytes >= byteWidth, "buffer access out of bounds") -- prevent crashes in --!native mode

	if byteWidth > 4 then -- outside of `bit32`'s functionality
		-- `chunkSize` is initialised as this to align the rest of calls to bytes, otherwise it is likely that
		-- a stack overflow occurs if it's not already byte aligned, this is because reading an unaligned 32 bit
		-- integer needs to read 5 bytes of data rather than just 4.
		local position, chunkSize = 0, 8 - bit

		-- This effectively iterates over all the groups of 32 bits, but clamps 32 to how many bits are left.
		repeat
			local mask = bit32.lshift(1, chunkSize) -- 2^chunkSize

			-- effectively rshift the value
			local chunk = value % mask
			value //= mask

			bitbuffer.write(b, offset + position, chunk, chunkSize)

			position += chunkSize
			chunkSize = math.min(width - position, 32) -- When we're on the final read call we can't read a full 4 bytes.
		until position == width
	elseif bit == 0 and width == byteWidth then -- Fully aligned to bits 8, 16, 24 and 32, allows for normal functions to be used.
		BUFFER_WRITE[byteWidth](b, byte, value)
	else -- Confined within one write call.
		BUFFER_WRITE[byteWidth](b, byte, bit32.replace(BUFFER_READ[byteWidth](b, byte), value, bit, width))
	end
end

-- A functio that automatically constructs `tobase` functions given the lookup of numbers to their
-- string forms, along with some other configuration parameters.
local function tobase(prefix: string, defaultSeparator: string, lookup: { [number]: string })
	local width = math.log(#lookup + 1, 2) -- calculates how many bits are represented by the lookup table
	assert(width % 1 == 0, "invalid length of lookup table") -- validates whether the lookup table's length is a power of 2

	return function(b: buffer, separator: string?, addPrefix: boolean?): string
		local bitCount = bit32.lshift(buffer.len(b), 3) -- buffer.len(b) * 8
		local characterCount = math.ceil(bitCount / width) -- how many `width`s fit into `bitCount`

		local output = table.create(characterCount + (if addPrefix then 1 else 0))
		if addPrefix then table.insert(output, prefix) end

		-- iterate over each code in the buffer
		for offset = 0, (characterCount - 1) * width, width do
			local byteWidth = math.min(width, bitCount - offset) -- prevent reading over the end of the buffer
			local byte = bit32.lshift(bitbuffer.read(b, offset, byteWidth), width - byteWidth) -- `lshift` to account for missing bits if we're at the end
			table.insert(output, lookup[byte])
		end

		return table.concat(output, separator or defaultSeparator)
	end
end

-- Use the `tobase` constructor function for some debug/serialisation functions.
bitbuffer.tobinary = tobase("0b", "_", BINARY_LOOKUP)
bitbuffer.tohex = tobase("0x", "_", HEX_LOOKUP)
bitbuffer.tobase64 = tobase("", "", BASE64_LOOKUP)

return bitbuffer
