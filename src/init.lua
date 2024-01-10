--!native
--!optimize 2

-- Any usage of `bit32.lshift` and `bit32.rshift` where the displacement is `3` emulate integer division
-- and multiplication by 8 (2^3, hence the 3), this is done because bitshifting is faster than generic
-- mathmatical operations.

local Bases = require(script.BaseLookup)
local Mutators = require(script.Mutators)

local bitbuffer = {}

local function writer(options)
	local toBufferSpace, readers, writers = options.toBufferSpace, options.read, options.write

	local function write(b: buffer, offset: number, value: number, width: number)
		local byte, bit, byteWidth = toBufferSpace(offset, width)
		assert(offset + width <= bit32.lshift(buffer.len(b), 3), "buffer access out of bounds") -- prevent crashes in native mode

		if byteWidth > 4 then -- outside of `bit32`'s functionality
			assert(width <= 48, "`bitbuffer` does not suppoer `width`s greater than 48")

			local position = 0
			repeat
				local chunkSize = math.min(width - position, 24) -- When we're on the final read call we can't read a full 3 bytes.

				local mask = bit32.lshift(1, chunkSize) -- 2^chunkSize
				local chunk = value % mask -- bit32.band(value, mask - 1)
				value = value // mask -- bit32.rshift(value, chunkSize)

				write(b, offset + position, chunk, chunkSize)
				position += chunkSize
			until position == width
		elseif bit == 0 and width == byteWidth then -- Fully aligned to bits 8, 16, 24 and 32, allows for normal functions to be used.
			writers[byteWidth](b, byte, value)
		else -- Confined within one write call.
			writers[byteWidth](b, byte, bit32.replace(readers[byteWidth](b, byte), value, bit, width))
		end
	end

	return write
end

local function reader(options)
	local toBufferSpace, readers, writers = options.toBufferSpace, options.read, options.write

	local function read(b: buffer, offset: number, width: number)
		local byte, bit, byteWidth = toBufferSpace(offset, width)
		assert(offset + width <= bit32.lshift(buffer.len(b), 3), "buffer access out of bounds") -- prevent crashes in native mode

		if byteWidth > 4 then -- outside of `bit32`'s functionality
			assert(width <= 48, "`bitbuffer` does not suppoer `width`s greater than 48")

			local value, position = 0, 0

			repeat
				local chunkSize = math.min(width - position, 24) -- When we're on the final read call we can't read a full 3 bytes.
				value += read(b, offset + position, chunkSize) * bit32.lshift(1, position) -- * 2^position
				position += chunkSize
			until position == width

			return value
		elseif bit == 0 and width == byteWidth then -- Fully aligned to bits 8, 16, 24 and 32, allows for normal functions to be used.
			return readers[byteWidth](b, byte)
		else -- Confined within one read call.
			return bit32.extract(readers[byteWidth](b, byte), bit, width)
		end
	end

	return read
end

-- A function that automatically constructs `tobase` functions given the lookup of numbers to their
-- string forms, along with some other configuration parameters.
local function tobase(options: {
	prefix: string,
	separator: string,
	paddingCharacters: { string }?,
	characters: { [number]: string },
	reader: (b: buffer, offset: number, width: number) -> number,
})
	local defaultPrefix, defaultSeparator, paddingCharacters, characters, read =
		options.prefix, options.separator, options.paddingCharacters, options.characters, options.reader

	local width = math.log(#characters + 1, 2) -- Calculates how many bits are represented by the lookup table.
	assert(width % 1 == 0, "this lookup table does not represent a whole number of bits")
	assert(
		not paddingCharacters and width % 8 == 0 or paddingCharacters,
		"padding is required for bases that are not byte aligned"
	)

	return function(b: buffer, separator: string?, prefix: (string | boolean)?): string
		local byteCount = buffer.len(b)
		local bitCount = bit32.lshift(byteCount, 3) -- buffer.len(b) * 8
		local characterCount = math.ceil(bitCount / width)

		local output = table.create(characterCount)

		-- iterate over each code in the buffer
		local endOffset = (characterCount - 1) * width
		for offset = 0, endOffset, width do
			local byteWidth = math.min(width, bitCount - offset) -- Prevent reading over the end of the buffer.
			local byte = bit32.lshift(read(b, offset, byteWidth), width - byteWidth) -- `lshift` to account for missing bits if we're at the end.
			table.insert(output, characters[byte])
		end

		local prefixString = if typeof(prefix) == "string" then prefix elseif prefix == true then defaultPrefix else ""
		local suffixString = if paddingCharacters then paddingCharacters[byteCount % #paddingCharacters + 1] else ""

		return string.format("%s%s%s", prefixString, table.concat(output, separator or defaultSeparator), suffixString)
	end
end

bitbuffer.read = reader(Mutators.Logical)
bitbuffer.write = writer(Mutators.Logical)

bitbuffer.fastread = reader(Mutators.Fast)
bitbuffer.fastwrite = writer(Mutators.Fast)

bitbuffer.tobinary = tobase({
	characters = Bases.Binary,
	reader = bitbuffer.fastread,
	prefix = "0b",
	separator = "_",
})

bitbuffer.tohex = tobase({
	characters = Bases.Hexadecimal,
	reader = bitbuffer.fastread,
	prefix = "0x",
	separator = " ",
})

bitbuffer.tobase64 = tobase({
	characters = Bases.Base64,
	reader = bitbuffer.read,
	paddingCharacters = { "", "==", "=" },
	prefix = "",
	separator = "",
})

return bitbuffer
