--!native
--!optimize 2

-- Any usage of `bit32.lshift` and `bit32.rshift` where the displacement is `3` emulate integer division
-- and multiplication by 8 (2^3, hence the 3), this is done because bitshifting is faster than generic
-- mathmatical operations.

type Reader = (b: buffer, offset: number, width: number) -> number
type Writer = (b: buffer, offset: number, value: number, width: number) -> ()

type ToBase = (b: buffer, separator: string?, prefix: (string | boolean)?) -> string
type FromBase = (str: string) -> buffer

local Bases = require(script.BaseLookup)
local Mutators = require(script.Mutators)

local bitbuffer = {}

local function createByteTransformer(characters: { [number]: string }, separator: string): (string) -> string
	local copy = {}
	for value, character in characters do
		copy[string.char(value)] = character .. separator
	end

	return function(char: string)
		return copy[char]
	end
end

local function mutator(options): (Reader, Writer)
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
		else -- Confined within one write call.
			writers[byteWidth](b, byte, bit32.replace(readers[byteWidth](b, byte), value, bit, width))
		end
	end

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
		local defaultTransformer = createByteTransformer(characters, defaultSeparator)
		function tobase(b, separator, prefix)
			local transformer = if separator then createByteTransformer(characters, separator) else defaultTransformer
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

bitbuffer.read, bitbuffer.write = mutator(Mutators.Logical)
bitbuffer.fastread, bitbuffer.fastwrite = mutator(Mutators.Fast)

bitbuffer.tobinary, bitbuffer.frombinary = base({
	characters = Bases.Binary,
	prefix = "0b",
	separator = "_",
	read = bitbuffer.fastread,
	write = bitbuffer.fastwrite,
})

bitbuffer.tohex, bitbuffer.fromhex = base({
	characters = Bases.Hexadecimal,
	prefix = "0x",
	separator = " ",
	read = bitbuffer.fastread,
	write = bitbuffer.fastwrite,
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
