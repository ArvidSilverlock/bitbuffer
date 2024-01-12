--!native
--!optimize 2

-- Any usage of `bit32.lshift` and `bit32.rshift` where the displacement is `3` emulate integer division
-- and multiplication by 8 (2^3, hence the 3), this is done because bitshifting is faster than generic
-- mathmatical operations.

type Reader = (b: buffer, offset: number, width: number) -> number
type Writer = (b: buffer, offset: number, value: number, width: number) -> ()

type ToBase = (b: buffer, separator: string?, prefix: (string | boolean)?, useLittleEndian: boolean?) -> string
type FromBase = (str: string) -> buffer

local Bases = require(script.BaseLookup)
local Mutators = require(script.Mutators)

local Manipulators = require(script.Manipulators)

local FLIP_ENDIAN = Bases.FlipEndian
local POWERS_OF_TWO = {}

for i = 0, 64 do
	POWERS_OF_TWO[i] = 2 ^ i
end

local function createByteTransformer(
	characters: { [number]: string },
	separator: string,
	bigEndian: boolean
): (string) -> string
	local copy = {}

	for value, character in characters do
		value = if bigEndian then FLIP_ENDIAN[value] else value
		copy[string.char(value)] = character .. separator
	end

	return function(char)
		return copy[char]
	end
end

local function writer(options): Writer
	local toBufferSpace, bitIterate = options.toBufferSpace, options.bitIterate
	local readers, writers = options.read, options.write

	local function write(b: buffer, offset: number, value: number, width: number)
		assert(offset + width <= bit32.lshift(buffer.len(b), 3), "buffer access out of bounds") -- prevent crashes in native mode
		local byte, bit, byteWidth = toBufferSpace(offset, width)

		if byteWidth > 4 then -- Outside of `bit32`'s functionality
			assert(width <= 52, "`bitbuffer` does not support `width`s greater than 52")

			for position, chunkWidth in bitIterate(width, bit) do
				local mask = POWERS_OF_TWO[chunkWidth]
				local chunk = value % mask
				value //= mask

				write(b, offset + position, chunk, chunkWidth)
			end
		elseif bit == 0 and width == bit32.lshift(byteWidth, 3) then -- Aligned to the bytes
			writers[byteWidth](b, byte, value)
		else -- Confined within one write call.
			assert(width > 0, "`width` must be greater than or equal to 1")
			writers[byteWidth](b, byte, bit32.replace(readers[byteWidth](b, byte), value, bit, width))
		end
	end

	return write
end

local function reader(options): Reader
	local toBufferSpace, bitIterate = options.toBufferSpace, options.bitIterate
	local readers, writers = options.read, options.write
	local getShiftValue = options.getShiftValue

	local function read(b: buffer, offset: number, width: number)
		local byte, bit, byteWidth = toBufferSpace(offset, width)
		assert(offset + width <= bit32.lshift(buffer.len(b), 3), "buffer access out of bounds") -- prevent crashes in native mode

		if byteWidth > 4 then -- outside of `bit32`'s functionality
			assert(width <= 52, "`bitbuffer` does not support `width`s greater than 52")

			local value = 0
			for position, chunkWidth in bitIterate(width, bit) do
				local shiftValue = getShiftValue(position, width, chunkWidth)
				value += read(b, offset + position, chunkWidth) * 2 ^ shiftValue
			end
			return value
		elseif bit == 0 and width == bit32.lshift(byteWidth, 3) then -- Aligned to the bytes
			return readers[byteWidth](b, byte)
		else -- Confined within one read call.
			assert(width > 0, "`width` must be greater than or equal to 1")
			return bit32.extract(readers[byteWidth](b, byte), bit, width)
		end
	end

	return read
end

-- A function that automatically constructs `tobase` functions given the lookup of numbers to their
-- string forms, along with some other configuration parameters.
local function base(options: {
	prefix: string,
	separator: string,
	paddingCharacter: string?,
	characters: { [number]: string },
	read: Reader,
	write: Writer,
}): (ToBase, FromBase)
	local defaultPrefix, defaultSeparator, paddingCharacter, characters =
		options.prefix, options.separator, options.paddingCharacter, options.characters

	local read, write = options.read, options.write

	local width = math.log(#characters + 1, 2) -- Calculates how many bits are represented by the lookup table.
	assert(width % 1 == 0, "this lookup table does not represent a whole number of bits")
	assert(
		not paddingCharacter and math.log(width, 2) % 1 == 0 or paddingCharacter,
		"padding is required for bases whose bit width is not a power of 2"
	)

	local paddingPattern = if paddingCharacter then `{paddingCharacter}*$` else nil

	local decode = {}
	local codeLength = #characters[0]
	for code, character in characters do
		assert(#character == codeLength, "character code length must be consistent")
		decode[character] = code
	end

	local tobase
	if width == 8 then -- if it's only ever byte aligned, you can use `buffer.tostring` along with `gsub` for speed increases
		local bigEndianTransformer = createByteTransformer(characters, defaultSeparator, false)
		local littleEndianTransformer = createByteTransformer(characters, defaultSeparator, true)

		function tobase(b, separator, prefix, useLittleEndian)
			local transformer = if separator
				then createByteTransformer(characters, separator, useLittleEndian)
				elseif useLittleEndian then littleEndianTransformer
				else bigEndianTransformer

			local separatorLength = string.len(separator or defaultSeparator)

			local prefixString = if type(prefix) == "string" then prefix elseif prefix == true then defaultPrefix else ""
			local outputBody = buffer.tostring(b):gsub(".", transformer):sub(1, -separatorLength - 1)

			return prefixString .. outputBody
		end
	else
		-- https://www.desmos.com/calculator/hgzcqadocn, don't know if this is a universal formula
		-- but it looks *about* right, and it works for base64
		local p = 2 ^ math.ceil(math.log(width, 2)) - width
		local function getPadding(bytes: number)
			local count = p - (bytes - 1) % (p + 1)
			return paddingCharacter:rep(count)
		end

		function tobase(b, separator, prefix)
			local byteCount = buffer.len(b)
			local bitCount = bit32.lshift(byteCount, 3) -- byteCount * 8
			local characterCount = math.ceil(bitCount / width)

			local output, outputIndex = table.create(characterCount), 1

			local endOffset = (characterCount - 1) * width
			local overhang = bitCount - endOffset

			-- iterate over each code in the buffer that doesn't extend over the end
			for offset = 0, endOffset - overhang, width do
				local code = read(b, offset, width)
				output[outputIndex] = characters[code]
				outputIndex += 1
			end

			-- if there is a code that extends over the end
			if overhang > 0 then
				local code = bit32.lshift(read(b, endOffset, overhang), width - overhang) -- `lshift` to account for missing bits that would be present over the end
				output[outputIndex] = characters[code]
				outputIndex += 1
			end

			local prefixString = if type(prefix) == "string" then prefix elseif prefix then defaultPrefix else ""
			local outputBody = table.concat(output, separator or defaultSeparator)
			local suffixString = if paddingCharacter then getPadding(byteCount) else ""

			return prefixString .. outputBody .. suffixString
		end
	end

	local function frombase(str)
		local paddingLength = 0
		if paddingPattern then
			local paddingStart, paddingEnd = str:find(paddingPattern)
			paddingLength = (paddingEnd - paddingStart + 1) // #paddingCharacter
		end

		local codeCount = #str // codeLength - paddingLength

		local bitCount = (codeCount * width) - (paddingLength * 2)
		local output = buffer.create(bit32.rshift(bitCount, 3))

		for i = 0, codeCount - 1 do
			local stringOffset, offset = i * codeLength, i * width
			local codeWidth = math.min(width, bitCount - offset)

			local code = decode[str:sub(stringOffset + 1, stringOffset + codeLength)]
			write(output, offset, bit32.rshift(code, width - codeWidth), codeWidth)
		end

		return output
	end

	return tobase, frombase
end

--- @class bitbuffer
local bitbuffer = {}

--[=[
	@function read
	@within bitbuffer

	Reads a `value` from a buffer in big endian format.

	@param b buffer -- The buffer to read from
	@param offset number -- The offset (in bits) to read from
	@param width number -- The width (in bits) of the value you're reading
]=]
bitbuffer.read = reader(Mutators.BigEndian)

--[=[
	@function write
	@within bitbuffer

	Writes a `value` into a buffer in big endian format.

	@param b buffer -- The buffer to write to
	@param offset number -- The offset (in bits) to write at
	@param value number -- The value you want to write
	@param width number -- The width (in bits) of the value
]=]
bitbuffer.write = writer(Mutators.BigEndian)

--[=[
	@function readlittle
	@within bitbuffer

	Reads a `value` from a buffer in little endian format.

	@param b buffer -- The buffer to read from
	@param offset number -- The offset (in bits) to read from
	@param width number -- The width (in bits) of the value you're reading
]=]
bitbuffer.readlittle = reader(Mutators.LittleEndian)

--[=[
	@function writelittle
	@within bitbuffer

	Writes a `value` into a buffer in little endian format.

	@param b buffer -- The buffer to write to
	@param offset number -- The offset (in bits) to write at
	@param value number -- The value you want to write
	@param width number -- The width (in bits) of the value
]=]
bitbuffer.writelittle = writer(Mutators.LittleEndian)

--[=[
	@function tobinary
	@within bitbuffer

	Converts a given buffer to a binary string.
	
	@param b buffer -- The buffer to convert to a string
	@param separator string? -- The string to separate each byte with, if not specified, each byte is separated by an underscore.
	@param prefix (string | boolean)? -- If prefix is `true`, it will be prefixed with `0b`, whereas if it is a `string`, the `string` itself will be used.
	@param useLittleEndian boolean? -- Whether or not to output it in little endian format.
	@return string
]=]

--[=[
	@function frombinary
	@within bitbuffer

	Converts a given binary string into a buffer. No characters besides `1` and `0` may be present.
	
	@param str string -- The string to convert into a buffer
	@return buffer
]=]

bitbuffer.tobinary, bitbuffer.frombinary = base({
	characters = Bases.Binary,
	prefix = "0b",
	separator = "_",
	read = bitbuffer.readlittle,
	write = bitbuffer.writelittle,
})

--[=[
	@function tohex
	@within bitbuffer

	Converts a given buffer to a hexadecimal string.
	
	@param b buffer -- The buffer to convert to a string
	@param separator string? -- The string to separate each byte with, if not specified, each byte is separated by a space.
	@param prefix (string | boolean)? -- If prefix is `true`, it will be prefixed with `0x`, whereas if it is a `string`, the `string` itself will be used.
	@param useLittleEndian boolean? -- Whether or not to output it in little endian format.
	@return string
]=]

--[=[
	@function fromhex
	@within bitbuffer

	Converts a given hexadecimal string into a buffer. No characters besides hexadecimal characters may be present.
	
	@param str string -- The string to convert into a buffer
	@return buffer
]=]

bitbuffer.tohex, bitbuffer.fromhex = base({
	characters = Bases.Hexadecimal,
	prefix = "0x",
	separator = " ",
	read = bitbuffer.readlittle,
	write = bitbuffer.writelittle,
})

--[=[
	@function tobase64
	@within bitbuffer

	Converts a given buffer to a binary string.
	
	@param b buffer -- The buffer to convert to a string
	@param separator string? -- The string to separate every 6 bits with, if not specified, no separator will be used.
	@param prefix string? -- The string to prefix the output with.
	@return string
]=]

--[=[
	@function frombase64
	@within bitbuffer

	Converts a given base64 string into a buffer.
	
	@param str string -- The string to convert into a buffer
	@return buffer
]=]

bitbuffer.tobase64, bitbuffer.frombase64 = base({
	characters = Bases.Base64,
	paddingCharacter = "=",
	prefix = "",
	separator = "",
	read = bitbuffer.read,
	write = bitbuffer.write,
})

--[=[
	@function reader
	@within bitbuffer

	Creates a `Reader` object for a buffer.
	
	@param b buffer -- The buffer to read from
	@param useLittleEndian boolean -- Whether to read values in little endian
	@return buffer
]=]
function bitbuffer.reader(b: buffer, useLittleEndian: boolean?)
	return setmetatable({
		_buffer = b,
		_offset = 0,
		read = if useLittleEndian then bitbuffer.readlittle else bitbuffer.read,
	}, Manipulators.Reader)
end

--[=[
	@function writer
	@within bitbuffer

	Creates a `Writer` object for a buffer.
	
	@param b buffer -- The buffer to write to
	@param useLittleEndian boolean -- Whether to write values in little endian
	@return buffer
]=]
function bitbuffer.writer(b: buffer, useLittleEndian: boolean?)
	return setmetatable({
		_buffer = b,
		_offset = 0,
		write = if useLittleEndian then bitbuffer.writelittle else bitbuffer.write,
	}, Manipulators.Writer)
end

return bitbuffer
