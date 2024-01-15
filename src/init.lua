--!native
--!optimize 2
--!strict

-- Any usage of `bit32.lshift` and `bit32.rshift` where the displacement is `3` emulate integer division
-- and multiplication by 8 (2^3, hence the 3), this is done because bitshifting is faster than generic
-- mathmatical operations.

local Types = require(script.Types)
local Constants = require(script.Constants)
local BufferEndians = require(script.BufferEndians)

local Editors = require(script.Editors)
local Reader = Editors.Reader
local Writer = Editors.Writer

local POWERS_OF_TWO = Constants.PowersOfTwo
local FLIP_ENDIAN = Constants.FlipEndian

local function createByteTransformer(
	characters: { [number]: string },
	separator: string,
	useBigEndian: boolean
): (string) -> string
	local copy = {}

	for value, character in characters do
		value = if useBigEndian then value else FLIP_ENDIAN[value]
		copy[string.char(value)] = character .. separator
	end

	return function(char)
		return copy[char]
	end
end

local function writer(options): Types.Write
	local toBufferSpace, bitIterate = options.toBufferSpace, options.bitIterate
	local readers, writers = options.read, options.write

	local function write(b: buffer, offset: number, value: number, width: number)
		assert(offset < 0 or offset + width <= bit32.lshift(buffer.len(b), 3), "buffer access out of bounds") -- prevent crashes in native mode
		assert(width > 0, "`width` must be greater than or equal to 1")

		local byte, bit, byteWidth = toBufferSpace(offset, width)

		if byteWidth > 4 then -- Outside of `bit32`'s functionality
			assert(width <= 53, "`width` must be less than or equal to 53")

			for position, chunkWidth in bitIterate(width, bit) do
				local mask = POWERS_OF_TWO[chunkWidth]
				local chunk = value % mask
				value //= mask

				write(b, offset + position, chunk, chunkWidth)
			end
		elseif bit == 0 and width == bit32.lshift(byteWidth, 3) then -- Aligned to the bytes.
			writers[byteWidth](b, byte, value)
		else -- Confined within one write call.
			writers[byteWidth](b, byte, bit32.replace(readers[byteWidth](b, byte), value, bit, width))
		end
	end

	return write
end

local function reader(options): Types.Read
	local toBufferSpace, bitIterate = options.toBufferSpace, options.bitIterate
	local readers, writers = options.read, options.write
	local getShiftValue = options.getShiftValue

	local function read(b: buffer, offset: number, width: number)
		assert(offset < 0 or offset + width <= bit32.lshift(buffer.len(b), 3), "buffer access out of bounds") -- prevent crashes in native mode
		assert(width > 0, "`width` must be greater than or equal to 1")
		
		local byte, bit, byteWidth = toBufferSpace(offset, width)

		if byteWidth > 4 then -- outside of `bit32`'s functionality
			assert(width <= 53, "`width` must be less than or equal to 53")

			local value = 0
			for position, chunkWidth in bitIterate(width, bit) do
				local shiftValue = getShiftValue(position, width, chunkWidth)
				value += (read(b, offset + position, chunkWidth) :: number) * 2 ^ shiftValue
			end
			return value
		elseif bit == 0 and width == bit32.lshift(byteWidth, 3) then -- Aligned to the bytes.
			return readers[byteWidth](b, byte)
		else -- Confined within one read call.
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
	read: Types.Read,
	write: Types.Write,
}): (Types.ToBase, Types.FromBase)
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
		local littleEndianTransformer = createByteTransformer(characters, defaultSeparator, false)
		local bigEndianTransformer = createByteTransformer(characters, defaultSeparator, true)

		function tobase(b, separator, prefix, useBigEndian)
			local transformer = if separator
				then createByteTransformer(characters, separator, useBigEndian)
				elseif useBigEndian then bigEndianTransformer
				else littleEndianTransformer

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
			return string.rep(paddingCharacter :: string, count)
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
			local paddingStart: number, paddingEnd: number = str:find(paddingPattern)
			paddingLength = (paddingEnd - paddingStart + 1) // #(paddingCharacter :: string)
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

	return tobase :: any, frombase :: any
end

--- @class bitbuffer
local bitbuffer = {}

--[=[
	@function read
	@within bitbuffer

	Reads a `value` from a buffer in little endian format.

	@param b buffer -- The buffer to read from
	@param offset number -- The offset (in bits) to read from
	@param width number -- The width (in bits) of the value you're reading
]=]
bitbuffer.read = reader(BufferEndians.Little)

--[=[
	@function write
	@within bitbuffer

	Writes a `value` into a buffer in little endian format.

	@param b buffer -- The buffer to write to
	@param offset number -- The offset (in bits) to write at
	@param value number -- The value you want to write
	@param width number -- The width (in bits) of the value
]=]
bitbuffer.write = writer(BufferEndians.Little)

--[=[
	@function readbig
	@within bitbuffer

	Reads a `value` from a buffer in big endian format.

	@param b buffer -- The buffer to read from
	@param offset number -- The offset (in bits) to read from
	@param width number -- The width (in bits) of the value you're reading
]=]
bitbuffer.readbig = reader(BufferEndians.Big)

--[=[
	@function writebig
	@within bitbuffer

	Writes a `value` into a buffer in big endian format.

	@param b buffer -- The buffer to write to
	@param offset number -- The offset (in bits) to write at
	@param value number -- The value you want to write
	@param width number -- The width (in bits) of the value
]=]
bitbuffer.writebig = writer(BufferEndians.Big)

--[=[
	@function tobinary
	@within bitbuffer

	Converts a given buffer to a binary string.
	
	@param b buffer -- The buffer to convert to a string
	@param separator string? -- The string to separate each byte with, if not specified, each byte is separated by an underscore.
	@param prefix (string | boolean)? -- If prefix is `true`, it will be prefixed with `0b`, whereas if it is a `string`, the `string` itself will be used.
	@param useBigEndian boolean? -- Whether or not to output it in big endian rather than little endian.

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
	characters = Constants.Binary,
	prefix = "0b",
	separator = "_",
	read = bitbuffer.read,
	write = bitbuffer.write,
})

--[=[
	@function tohex
	@within bitbuffer

	Converts a given buffer to a hexadecimal string.
	
	@param b buffer -- The buffer to convert to a string
	@param separator string? -- The string to separate each byte with, if not specified, each byte is separated by a space.
	@param prefix (string | boolean)? -- If prefix is `true`, it will be prefixed with `0x`, whereas if it is a `string`, the `string` itself will be used.
	@param useBigEndian boolean? -- Whether or not to output it in big endian rather than little endian.

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
	characters = Constants.Hexadecimal,
	prefix = "0x",
	separator = " ",
	read = bitbuffer.read,
	write = bitbuffer.write,
})

--[=[
	@function tobase64
	@within bitbuffer

	Converts a given buffer to a base64 string.
	
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
	characters = Constants.Base64,
	paddingCharacter = "=",
	prefix = "",
	separator = "",
	read = bitbuffer.readbig,
	write = bitbuffer.writebig,
})

--[=[
	@function reader
	@within bitbuffer

	Creates a `Reader` object for a buffer.
	
	@param b buffer -- The buffer to read from
	@param useBigEndian boolean -- Whether to read values in big endian (slower)
	
	@return Reader
]=]
function bitbuffer.reader(b: buffer, useBigEndian: boolean?): Types.Reader
	return setmetatable({
		_buffer = b,
		_offset = 0,

		_byte = 0,
		_isByteAligned = true,

		read = if useBigEndian then bitbuffer.readbig else bitbuffer.read,
	}, Reader) :: any
end

--[=[
	@function writer
	@within bitbuffer

	Creates a `Writer` object for a buffer.
	
	@param b buffer -- The buffer to write to
	@param useBigEndian boolean -- Whether to write values in big endian (slower)
	
	@return Writer
]=]
function bitbuffer.writer(b: buffer, useBigEndian: boolean?): Types.Writer
	return setmetatable({
		_buffer = b,
		_offset = 0,

		_byte = 0,
		_isByteAligned = true,

		write = if useBigEndian then bitbuffer.writebig else bitbuffer.write,
	}, Writer) :: any
end

return bitbuffer
