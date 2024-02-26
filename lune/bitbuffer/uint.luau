local Snippet = require("../Snippet.luau")

local readCalls = {}
local writeCalls = {}

local BYTE_ALIGNED_READ = {
	[8] = "buffer.readu8",
	[16] = "buffer.readu16",
	[24] = "readu24",
	[32] = "buffer.readu32",
}

local BYTE_ALIGNED_WRITE = {
	[8] = "buffer.writeu8",
	[16] = "buffer.writeu16",
	[24] = "writeu24",
	[32] = "buffer.writeu32",
}

local function alignedRead(width: number)
	local chunkCount = math.ceil(width / 32)

	local body = Snippet.new("buffer.readu32(b, byte) % ", string.format("0x%x", 2 ^ math.min(width, 32)))
	body:Indent()

	for index = 1, chunkCount - 1 do
		local position, bytePosition = index * 32, index * 4
		local chunkWidth = math.min(width - position, 32)

		local multiplier = string.format(" * 0x%x", 2 ^ position)
		local bound = string.format(" %% 0x%x", 2 ^ chunkWidth)

		local alignedWidth = math.ceil(chunkWidth / 8) * 8
		local readCallback = BYTE_ALIGNED_READ[alignedWidth]

		if chunkWidth == alignedWidth then
			body:Push("+ ", readCallback, "(b, byte + ", bytePosition, ")", multiplier)
		else
			body:Push("+ ", readCallback, "(b, byte + ", bytePosition, ")", bound, multiplier)
		end
	end

	return tostring(body)
end

local function unalignedRead(width: number)
	local chunkCount = math.ceil(width / 24)
	local position, chunkWidth = 0, math.min(width, 24)

	local body = Snippet.new("return bit32.extract(buffer.readu32(b, byte), bit, 24)"):Indent()

	for _ = 2, chunkCount do
		position += chunkWidth
		chunkWidth = math.min(width - position, 24)

		local multiplier = string.format(" * 0x%x", 2 ^ position)
		local offset = ` + {position / 8}`

		if chunkWidth == 24 then
			body:Push("+ bit32.extract(buffer.readu32(b, byte", offset, "), bit, ", chunkWidth, ")", multiplier)
		else
			local read = `{readCalls[chunkWidth]:gsub("byte", `byte{offset}`)}`
			if read:match("^if") then
				body:BlockStart("+ ("):Push(read):BlockEnd(`){multiplier}`)
			else
				body:Push("+ ", read, multiplier)
			end
		end
	end

	return tostring(body)
end

local function alignedWrite(width: number)
	local chunkCount = math.ceil(width / 32)
	local body = Snippet.new()

	for index = 0, chunkCount - 1 do
		local position = 32 * index
		local chunkWidth = math.min(width - position, 32)

		local alignedWidth = math.ceil(chunkWidth / 8) * 8
		local readCallback = BYTE_ALIGNED_READ[alignedWidth]
		local writeCallback = BYTE_ALIGNED_WRITE[alignedWidth]

		local divisor = if index > 0 then string.format(" // 0x%x", 2 ^ position) else ""

		if chunkWidth ~= alignedWidth then
			local replacement = `bit32.replace({readCallback}(b, byte), value{divisor}, 0, {chunkWidth})`
			body:ConditionalPush(index > 0, "byte += 4")
			body:Push(writeCallback, "(b, byte, ", replacement, ")")
		elseif index == 0 then
			body:Push(writeCallback, "(b, byte, value", divisor, ")")
		else
			body:Push(writeCallback, "(b, byte + 4, value", divisor, ")")
		end
	end

	return tostring(body)
end

local function unalignedWrite(width: number)
	local chunkCount = math.ceil(width / 24)
	local body = Snippet.new("buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 24))")

	for index = 1, chunkCount - 1 do
		local position = 24 * index
		local chunkWidth = math.min(width - position, 24)

		local divisor = string.format(" // 0x%x", 2 ^ position)
		body:Push("byte += 3")

		if chunkWidth == 24 then
			body:Push("buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value", divisor, ", bit, 24))")
		else
			body:Push((writeCalls[chunkWidth]:gsub("value", `value{divisor}`)))
		end
	end

	return tostring(body)
end

local function getReadCallback(width: number, threshold: number)
	if width <= 24 or (threshold < 0 and width <= 32) then
		local alignedWidth = math.ceil(width / 8) * 8

		local caseA = if width ~= alignedWidth
			then `bit32.extract({BYTE_ALIGNED_READ[alignedWidth]}(b, byte), bit, {width})`
			else `{BYTE_ALIGNED_READ[alignedWidth]}(b, byte)`

		local caseB = if threshold >= 0
			then `bit32.extract({BYTE_ALIGNED_READ[alignedWidth + 8]}(b, byte), bit, {width})`
			else nil

		return caseA, caseB, true
	else
		return alignedRead(width), unalignedRead(width), false
	end
end

local function getWriteCallback(width: number, threshold: number)
	if width <= 24 or (threshold < 0 and width <= 32) then
		local alignedWidth = math.ceil(width / 8) * 8
		local readCallback = BYTE_ALIGNED_READ[alignedWidth]
		local writeCallback = BYTE_ALIGNED_WRITE[alignedWidth]

		local caseA = if width ~= alignedWidth
			then `{writeCallback}(b, byte, bit32.replace({readCallback}(b, byte), value, bit, {width}))`
			else `{writeCallback}(b, byte, value)`

		local caseB = if threshold >= 0
			then `{BYTE_ALIGNED_WRITE[alignedWidth + 8]}(b, byte, bit32.replace({BYTE_ALIGNED_READ[alignedWidth + 8]}(b, byte), value, bit, {width}))`
			else nil

		return caseA, caseB
	else
		return alignedWrite(width), unalignedWrite(width)
	end
end

local function getBitThreshold(width: number): number
	return math.ceil((width - 1) / 8) * 8 - width
end

local function generateRead(luau, typescript)
	for width = 1, 53 do
		local bitThreshold = getBitThreshold(width)
		local alignedCase, unalignedCase, isSingleLine = getReadCallback(width, bitThreshold)

		local body = Snippet.new()
		if unalignedCase then
			if isSingleLine then
				body:Push(`return if bit > {if width > 24 then 0 else bitThreshold}`)
					:Indent()
					:Push("then ", unalignedCase)
					:Push("else ", alignedCase)
					:Indent(-1)
			else
				body:BlockStart(`if bit > {if width > 24 then 0 else bitThreshold} then`)
					:Push(unalignedCase)
					:BlockMiddle("else")
					:Push(`return {alignedCase}`)
					:BlockEnd()
			end
		else
			body:Push(`return {alignedCase}`)
		end

		readCalls[width] = if bitThreshold > 0
			then tostring(body):gsub("^return ", "")
			else unalignedCase or alignedCase

		local comment = `Reads a {width} bit unsigned integer [0, {2 ^ width - 1}]`

		luau:Push(`--- {comment}`)
			:BlockStart(`function bitbuffer.readu{width}(b: buffer, byte: number, bit: number): number`)
			:Merge(body)
			:BlockEnd()
			:ConditionalPush(width < 53, "")

		-- stylua: ignore
		typescript
			:Push(`/** {comment} */`)
			:Push("readu", width, ": read<number>;")
	end

	typescript:Push("")
end

local function generateWrite(luau, typescript)
	for width = 1, 53 do
		local bitThreshold = getBitThreshold(width)
		local alignedCase, unalignedCase = getWriteCallback(width, bitThreshold)

		local body = Snippet.new()
		if unalignedCase then
			body:BlockStart(`if bit > {if width > 24 then 0 else bitThreshold} then`)
				:Push(unalignedCase)
				:BlockMiddle("else")
				:Push(alignedCase)
				:BlockEnd()
		else
			body:Push(alignedCase)
		end

		writeCalls[width] = if bitThreshold > 0 then tostring(body) else unalignedCase or alignedCase

		local comment = `Writes a {width} bit unsigned integer [0, {2 ^ width - 1}]`

		luau:Push(`--- {comment}`)
			:BlockStart(`function bitbuffer.writeu{width}(b: buffer, byte: number, bit: number, value: number)`)
			:Merge(body)
			:BlockEnd()
			:ConditionalPush(width < 53, "")

		-- stylua: ignore
		typescript
			:Push(`/** {comment} */`)
			:Push("writeu", width, ": write<number>;")
	end

	typescript:Push("")
end

local function finalise(luau, typescript)
	local readLookup, writeLookup = {}, {}
	for width = 1, 53 do
		table.insert(readLookup, `bitbuffer.readu{width}`)
		table.insert(writeLookup, `bitbuffer.writeu{width}`)
	end

	luau:Push(`bitbuffer.readu = \{ {table.concat(readLookup, ", ")} \}`)
		:Push(`bitbuffer.writeu = \{ {table.concat(writeLookup, ", ")} \}`)

	typescript:Push("readu: Array<read<number>>"):Push("writeu: Array<write<number>>"):Push("")
end

local function create(luau, typescript)
	luau:Block("write", generateWrite, typescript):Block("read", generateRead, typescript):Call(finalise, typescript)
end

return create
