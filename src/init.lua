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

local FLIP_ENDIAN = Bases.FlipEndian

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

	return function(char: string)
		return copy[char]
	end
end

local function mutator(options): (Reader, Writer)
	local toBufferSpace, bitIterate = options.toBufferSpace, options.bitIterate
	local readers, writers = options.read, options.write
	local getShiftValue = options.getShiftValue

	local function write(b: buffer, offset: number, value: number, width: number)
		local byte, bit, byteWidth = toBufferSpace(offset, width)
		assert(offset + width <= bit32.lshift(buffer.len(b), 3), "buffer access out of bounds") -- prevent crashes in native mode

		if byteWidth > 4 then -- outside of `bit32`'s functionality
		assert(width <= 53, "`bitbuffer` does not support `width`s greater than 53")

			for position, chunkWidth in bitIterate(width, bit) do
				local mask = 2^chunkWidth
				local chunk = value % mask
				value //= mask
				
				write(b, offset + position, chunk, chunkWidth)
			end
		else
			assert(width > 0, "`width` must be greater than or equal to 1")
			writers[byteWidth](b, byte, bit32.replace(readers[byteWidth](b, byte), value, bit, width))
		end
	end

	local function read(b: buffer, offset: number, width: number)
		local byte, bit, byteWidth = toBufferSpace(offset, width)
		assert(offset + width <= bit32.lshift(buffer.len(b), 3), "buffer access out of bounds") -- prevent crashes in native mode

		if byteWidth > 4 then -- outside of `bit32`'s functionality
			assert(width <= 53, "`bitbuffer` does not support `width`s greater than 53")

			local value = 0
			for position, chunkWidth in bitIterate(width, bit) do
				local shiftValue = getShiftValue(position, width, chunkWidth)
				value += read(b, offset + position, chunkWidth) * 2^shiftValue
			end
			return value
		else -- Confined within one read call.
			return bit32.extract(readers[byteWidth](b, byte), bit, width)
		end
	end

	return read, write
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

			local prefixString = if type(prefix) == "string" then prefix elseif prefix then defaultPrefix else ""
			local outputBody = buffer.tostring(b):gsub(".", transformer):sub(1, -separatorLength - 1)

			return string.format("%s%s", prefixString, outputBody)
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

			local output = table.create(characterCount)

			local endOffset = (characterCount - 1) * width
			local overhang = bitCount - endOffset

			-- iterate over each code in the buffer that doesn't extend over the end
			for offset = 0, endOffset - overhang, width do
				local code = read(b, offset, width)
				table.insert(output, characters[code])
			end

			-- if there is a code that extends over the end
			if overhang > 0 then
				local code = bit32.lshift(read(b, endOffset, overhang), width - overhang) -- `lshift` to account for missing bits that would be present over the end
				table.insert(output, characters[code])
			end

			local prefixString = if type(prefix) == "string" then prefix elseif prefix then defaultPrefix else ""
			local outputBody = table.concat(output, separator or defaultSeparator)
			local suffixString = if paddingCharacter then getPadding(byteCount) else ""

			return string.format("%s%s%s", prefixString, outputBody, suffixString)
		end
	end

	local function frombase(str)
		local paddingLength = if paddingPattern then #str:match(paddingPattern) / #paddingCharacter else 0
		local codeCount = #str / codeLength - paddingLength

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

local bitbuffer = {}

bitbuffer.read, bitbuffer.write = mutator(Mutators.BigEndian)
bitbuffer.readlittle, bitbuffer.writelittle = mutator(Mutators.LittleEndian)

bitbuffer.tobinary, bitbuffer.frombinary = base({
	characters = Bases.Binary,
	prefix = "0b",
	separator = "_",
	read = bitbuffer.readlittle,
	write = bitbuffer.writelittle,
})

bitbuffer.tohex, bitbuffer.fromhex = base({
	characters = Bases.Hexadecimal,
	prefix = "0x",
	separator = " ",
	read = bitbuffer.readlittle,
	write = bitbuffer.writelittle,
})

bitbuffer.tobase64, bitbuffer.frombase64 = base({
	characters = Bases.Base64,
	paddingCharacter = "=",
	prefix = "",
	separator = "",
	read = bitbuffer.read,
	write = bitbuffer.write,
})

return bitbuffer
