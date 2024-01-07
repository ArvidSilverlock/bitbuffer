--!native
--!optimize 2

--[[
	I am no mathematician, never worked with bytes, let alone bits before. There's probably a way better
	method of calculating most of the things I calculate, most of this was done via trial and error.

	Some changes that could be made include:
	> Implementing custom `read`/`write` 24 bit functions (adjust width map accordingly), this would
	  allow for omission of the 'hangs over beginning and end' case, as this would be accounted for
	  by default.
]]

local BASE64_VALUES = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- These make the `tostring` functions much faster, as it doesn't need to re-create the string forms
-- of all the numbers again, just reads if from the lookup tables.
local BINARY_LOOKUP = {}
local BASE64_LOOKUP = {}
local HEX_LOOKUP = {}

do -- Precalculation of the `tobase` formats.
	for i = 0, 255 do
		local binaryValue = table.create(8)
		for j = 0, 7 do
			table.insert(binaryValue, bit32.extract(i, j, 1))
		end

		BINARY_LOOKUP[i] = table.concat(binaryValue)
		HEX_LOOKUP[i] = string.format("%02x", i)
	end

	for i = 0, 63 do
		BASE64_LOOKUP[i] = BASE64_VALUES:sub(i + 1, i + 1)
	end
end

-- Dictionary of bit widths to `read`/`write` widths.
local WIDTH_MAP = {}
for i = 1, 32 do
	WIDTH_MAP[i] = math.max(2 ^ math.ceil(math.log(i, 2)), 8)
end

-- Getting the `read`/`write` functions from the width map values.
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

--[[
	Any usage of `bit32.lshift` and `bit32.rshift` where the displacement is `3` emulate integer division
	and multiplication by 8 (2^3, hence the 3), this is done because bitshifting is faster than generic
	mathmatical operations.

	The reason that the `offset` is inverted for the bit calculation is because the `byte`
	index is left to right but the `bit` index is right to left.
]]
local function toBufferSpace(bufferLength: number, offset: number, width: number): (number, number, number)
	local byte = bit32.rshift(offset, 3)
	local bit = bit32.band(offset, 0b111)

	local remainingBytes = bufferLength - byte
	local readWidth = bit32.rshift(bit + width + 7, 3)

	return byte, bit, readWidth, remainingBytes
end

local bitbuffer = {}

function bitbuffer.read(b: buffer, offset: number, width: number): number
	local bufferLength = buffer.len(b)
	local byte, bit, readWidth, remainingBytes = toBufferSpace(bufferLength, offset, width)

	assert(remainingBytes >= readWidth, "buffer access out of bounds")

	if readWidth > 4 then -- Outside of `bit32`'s functionality
		-- `chunkSize` is initialised as this to align the rest of calls to bytes
		local value, position, chunkSize = 0, 0, 8 - bit
		repeat
			value += bitbuffer.read(b, offset + position, chunkSize) * bit32.lshift(1, position)

			position += chunkSize
			chunkSize = math.min(width - position, 32)
		until position == width

		return value
	elseif bit == 0 and width == readWidth then -- Fully aligned to bits 8, 16 and 32.
		local read = BUFFER_READ[readWidth]
		return read(b, byte)
	elseif bit + width <= bit32.lshift(readWidth, 3) then -- Fits within one read call.
		local read = BUFFER_READ[readWidth]
		return bit32.extract(read(b, byte), bit, width)
	end
end

function bitbuffer.write(b: buffer, offset: number, value: number, width: number)
	local bufferLength = buffer.len(b)
	local byte, bit, readWidth, remainingBytes = toBufferSpace(bufferLength, offset, width)

	assert(remainingBytes >= readWidth, "buffer access out of bounds")

	if readWidth > 4 then -- Outside of `bit32`'s functionality
		-- `chunkSize` is initialised as this to align the rest of calls to bytes
		local position, chunkSize = 0, 8 - bit
		repeat
			local chunk = value % bit32.lshift(1, chunkSize)
			value = value // bit32.lshift(1, chunkSize)

			bitbuffer.write(b, offset + position, chunk, chunkSize)

			position += chunkSize
			chunkSize = math.min(width - position, 32)
		until position == width
	elseif bit == 0 and width == readWidth then -- Fully aligned to bits 8, 16, 24 and 32.
		local write = BUFFER_WRITE[readWidth]
		write(b, byte, value)
	elseif bit + width <= bit32.lshift(readWidth, 3) then -- Fits within one write call.
		local read, write = BUFFER_READ[readWidth], BUFFER_WRITE[readWidth]
		write(b, byte, bit32.replace(read(b, byte), value, bit, width))
	end
end

local function tobase(prefix: string, defaultSeparator: string, lookup: { [number]: string })
	local width = math.log(#lookup + 1, 2)
	assert(width % 1 == 0, "invalid length of lookup table")

	return function(b: buffer, separator: string?, addPrefix: boolean?): string
		local bufferLength = buffer.len(b)

		local bitCount = bit32.lshift(bufferLength, 3)
		local characterCount = math.ceil(bitCount / width)

		local output = table.create(characterCount)
		for i = 0, (characterCount - 1) * width, width do
			local readWidth = math.min(width, bitCount - i) -- Don't read over the end.
			local byte = bit32.lshift(bitbuffer.read(b, i, readWidth), width - readWidth) -- `lshift` to account for missing bits (see the line above).
			table.insert(output, lookup[byte])
		end

		return (if addPrefix ~= false then prefix else "") .. table.concat(output, separator or defaultSeparator)
	end
end

--[[
	You could call this code an affront to both gods and men, I call it the truly false way to abide
	by the DRY principle... look at it in all its glory, a whisper of elegance resonates in these
	few lines.

	Ignore the `read` and `write` functions being practically the same. They are different in
	spirit, and that's what counts (except in the case of the three lines below).
]]
bitbuffer.tobinary = tobase("0b", "_", BINARY_LOOKUP)
bitbuffer.tohex = tobase("0x", "_", HEX_LOOKUP)
bitbuffer.tobase64 = tobase("", "", BASE64_LOOKUP)

return bitbuffer
