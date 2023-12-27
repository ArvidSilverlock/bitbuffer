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

do -- Precalculation of the `tobase` formats
	for i = 0, 255 do
		local binaryValue = table.create(8)
		for j = 7, 0, -1 do
			table.insert(binaryValue, bit32.extract(i, j, 1))
		end

		BINARY_LOOKUP[i] = table.concat(binaryValue)
		HEX_LOOKUP[i] = string.format("%02x", i)
	end

	for i = 0, 63 do
		BASE64_LOOKUP[i] = BASE64_VALUES:sub(i + 1, i + 1)
	end
end

-- dictionary of bit widths to `read`/`write` widths
local WIDTH_MAP = {}
for i = 1, 32 do
	WIDTH_MAP[i] = math.max(2 ^ math.ceil(math.log(i, 2)), 8)
end

-- Getting the `read`/`write` functions from the width map values.
local BUFFER_READ = {
	[8] = buffer.readu8,
	[16] = buffer.readu16,
	[32] = buffer.readu32,
}

local BUFFER_WRITE = {
	[8] = buffer.writeu8,
	[16] = buffer.writeu16,
	[32] = buffer.writeu32,
}

--[[
	Any usage of `bit32.lshift` and `bit32.rshift` where the displacement is `3` emulate integer division
	and multiplication by 8 (2^3, hence the 3), this is done because bitshifting is faster than generic
	mathmatical operations.
]]

--[[
	The `lshift` looks like it just reverses the `rshift` but it's doing integer division,
	so in reality it's `offset // 8 * 8`.
	
	The reason that the `offset` is inverted is because the `byte` index is left to right but the
	`bit` index is right to left (which works fine in most cases if left, but is a bit unintuitive),
	the byte is re-inverted afterwards for backwards compatibility with normal `buffer` functions.
]]
local function toBufferSpace(bufferLength: number, offset: number, width: number): (number, number, number)
	local maxWidth = WIDTH_MAP[width]

	local byte = bit32.rshift(offset, 3)

	local invertedOffset = bit32.lshift(bufferLength, 3) - (offset + width)
	local bit = invertedOffset % 8

	local remainingBits = bit32.lshift(bufferLength, 3) - offset
	return byte, bit, maxWidth, remainingBits
end

local bitbuffer = {}

function bitbuffer.read(b: buffer, offset: number, width: number): number
	local bufferLength = buffer.len(b)
	local byte, bit, maxWidth, remainingBits = toBufferSpace(bufferLength, offset, width)

	if remainingBits < maxWidth then -- hangs over the end
		assert(width <= remainingBits, "buffer access out of bounds")

		-- recalculate our buffer position, except it's anchored to the end
		maxWidth = WIDTH_MAP[remainingBits]
		byte = bufferLength - bit32.rshift(maxWidth, 3)

		if byte < 0 then -- hangs over the beginning and the end, the only case for this is 3 bytes
			return buffer.readu8(b, 0) + bit32.lshift(buffer.readu16(b, 1), 8)
		else -- hangs over only the end
			bit = offset - bit32.lshift(byte, 3)
			local read = BUFFER_READ[maxWidth]
			return bit32.extract(read(b, byte), bit, width)
		end
	elseif bit == 0 and width == maxWidth then -- fully aligned to bytes 8, 16 and 32
		local read = BUFFER_READ[maxWidth]
		return read(b, byte)
	elseif bit + width <= maxWidth then -- fits within one read call
		local read = BUFFER_READ[maxWidth]
		return bit32.extract(read(b, byte), bit, width)
	else -- spans over two read calls
		local nextByte = byte + bit32.rshift(maxWidth, 3)
		local f = maxWidth - bit
		local s = width - f

		local readA, readB = BUFFER_READ[maxWidth], BUFFER_READ[WIDTH_MAP[s]]
		return bit32.extract(readA(b, byte), bit, f) + bit32.lshift(bit32.extract(readB(b, nextByte), 0, s), f)
	end
end

function bitbuffer.write(b: buffer, offset: number, value: number, width: number)
	local bufferLength = buffer.len(b)
	local byte, bit, maxWidth, remainingBits = toBufferSpace(bufferLength, offset, width)

	if remainingBits < maxWidth then -- Hangs over the end
		assert(width <= remainingBits, "buffer access out of bounds")

		-- recalculate our buffer position, except it's anchored to the end
		maxWidth = WIDTH_MAP[remainingBits]
		byte = bufferLength - bit32.rshift(maxWidth, 3)

		if byte < 0 then -- hangs over the beginning and end, the only case for this is 3 bytes
			buffer.writeu8(b, 0, bit32.extract(value, 0, 8))
			buffer.writeu16(b, 1, bit32.extract(value, 8, 24))
		else -- hangs over only the end
			bit = offset - bit32.lshift(byte, 3)
			local read, write = BUFFER_READ[maxWidth], BUFFER_WRITE[maxWidth]
			write(b, byte, bit32.replace(read(b, byte), value, bit, width))
		end
	elseif bit == 0 and width == maxWidth then -- fully aligned to bytes 8, 16 and 32
		local write = BUFFER_WRITE[maxWidth]
		write(b, byte, value)
	elseif bit + width <= maxWidth then -- fits within one write call
		local read, write = BUFFER_READ[maxWidth], BUFFER_WRITE[maxWidth]
		write(b, byte, bit32.replace(read(b, byte), value, bit, width))
	else -- spans over two write calls
		local nextByte = byte + bit32.rshift(maxWidth, 3)
		local f = maxWidth - bit
		local s = width - f

		local readA, writeA = BUFFER_READ[maxWidth], BUFFER_WRITE[maxWidth]
		writeA(b, byte, bit32.replace(readA(b, byte), bit32.extract(value, 0, f), bit, f))

		local widthB = WIDTH_MAP[s]
		local readB, writeB = BUFFER_READ[widthB], BUFFER_WRITE[widthB]
		writeB(b, nextByte, bit32.replace(readB(b, nextByte), bit32.extract(value, f, s), 0, s))
	end
end

local function tobase(lookup: { [number]: string })
	local width = math.log(#lookup + 1, 2)
	assert(width % 1 == 0, "invalid length of lookup table")

	return function(b: buffer, separator: string?): string
		local bufferLength = buffer.len(b)

		local bitCount = bit32.lshift(bufferLength, 3)
		local characterCount = math.ceil(bitCount / width)

		local output = table.create(characterCount)
		for i = 0, (characterCount - 1) * width, width do
			local readWidth = math.min(width, bitCount - i) -- don't read over the end
			local byte = bit32.lshift(bitbuffer.read(b, i, readWidth), width - readWidth) -- `lshift` to account for missing bits (see the line above)
			table.insert(output, lookup[byte])
		end

		return table.concat(output, separator or "")
	end
end

--[[
	You could call this code an affront to both gods and men, I call it the truly false way to abide
	by the DRY principle... look at it in all its glory, a whisper of elegance resonates in these
	few lines.

	Ignore the `read` and `write` functions being practically the same. They are different in
	spirit, and that's what counts (except in the case of the three lines below).
]]
bitbuffer.tobinary = tobase(BINARY_LOOKUP)
bitbuffer.tohex = tobase(HEX_LOOKUP)
bitbuffer.tobase64 = tobase(BASE64_LOOKUP)

return bitbuffer
