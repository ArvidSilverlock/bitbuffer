local Snippet = require("../Snippet.luau")

local GENERALISED_READ_WRITE = [[function bitbuffer.readu(b: buffer, offset: number, width: number): number
	return unsignedRead[width](b, offset)
end

function bitbuffer.writeu(b: buffer, offset: number, value: number, width: number)
	unsignedWrite[width](b, offset, value)
end]]

local LOCALISED_FUNCTIONS = [[local readu8 = buffer.readu8
local readu16 = buffer.readu16
local readu32 = buffer.readu32

local writeu8 = buffer.writeu8
local writeu16 = buffer.writeu16
local writeu32 = buffer.writeu32

local function readu24(b: buffer, offset: number)
	return readu8(b, offset) + readu16(b, offset + 1) * 256
end

local function writeu24(b: buffer, offset: number, value: number)
	writeu8(b, offset, value)
	writeu16(b, offset + 1, value // 256)
end

local bit32_replace = bit32.replace
local bit32_extract = bit32.extract]]

local readCalls = {}
local writeCalls = {}

local function alignedRead(width: number)
	local chunkCount = math.ceil(width / 32)
	local body = Snippet.new("readu32(b, byte) % ", string.format("0x%x", 2 ^ math.min(width, 32)))

	for index = 1, chunkCount - 1 do
		local position, bytePosition = index * 32, index * 4
		local chunkWidth = math.min(width - position, 32)

		local multiplier = string.format(" * 0x%x", 2 ^ position)
		local bound = string.format(" %% 0x%x", 2 ^ chunkWidth)

		local alignedWidth = math.ceil(chunkWidth / 8) * 8
		if chunkWidth == alignedWidth then
			body:Push("+ readu", alignedWidth, "(b, byte + ", bytePosition, ")", multiplier):Indent()
		else
			body:Push("+ readu", alignedWidth, "(b, byte + ", bytePosition, ")", bound, multiplier):Indent()
		end
	end

	return tostring(body)
end

local function unalignedRead(width: number)
	local chunkCount = math.ceil(width / 24)
	local position, chunkWidth = 0, math.min(width, 24)

	local body = Snippet.new()

	for _ = 2, chunkCount do
		position += chunkWidth
		chunkWidth = math.min(width - position, 24)

		local multiplier = string.format(" * 0x%x", 2 ^ position)
		local offset = ` + {position / 8}`

		if chunkWidth == 24 then
			body:Push("+ bit32_extract(readu32(b, byte", offset, "), bit, ", chunkWidth, ")", multiplier)
		else
			local read = `{readCalls[chunkWidth]:gsub("byte", `byte{offset}`)}`
			if read:match("^if") then
				body:Push("+ (")
				body:Push(read):Indent()
				body:Push(")", multiplier)
			else
				body:Push("+ ", read, multiplier)
			end
		end
	end

	body:Indent()
	body:Insert(1, "return bit32_extract(readu32(b, byte), bit, 24)")

	return tostring(body)
end

local function alignedWrite(width: number)
	local chunkCount = math.ceil(width / 32)
	local body = Snippet.new()

	for index = 0, chunkCount - 1 do
		local position = 32 * index
		local chunkWidth = math.min(width - position, 32)

		local alignedWidth = math.ceil(chunkWidth / 8) * 8
		local divisor = if index > 0 then string.format(" // 0x%x", 2 ^ position) else ""

		if chunkWidth ~= alignedWidth then
			local replacement = `bit32_replace(readu{alignedWidth}(b, byte), value{divisor}, 0, {chunkWidth})`
			body:ConditionalPush(index > 0, "byte += 4")
			body:Push("writeu", alignedWidth, "(b, byte, ", replacement, ")")
		elseif index == 0 then
			body:Push("writeu", alignedWidth, "(b, byte, value", divisor, ")")
		else
			body:Push("writeu", alignedWidth, "(b, byte + 4, value", divisor, ")")
		end
	end

	return tostring(body)
end

local function unalignedWrite(width: number)
	local chunkCount = math.ceil(width / 24)
	local body = Snippet.new("writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))")

	for index = 1, chunkCount - 1 do
		local position = 24 * index
		local chunkWidth = math.min(width - position, 24)

		local divisor = string.format(" // 0x%x", 2 ^ position)
		body:Push("byte += 3")

		if chunkWidth == 24 then
			body:Push("writeu32(b, byte, bit32_replace(readu32(b, byte), value", divisor, ", bit, 24))")
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
			then `bit32_extract(readu{alignedWidth}(b, byte), bit, {width})`
			else `readu{alignedWidth}(b, byte)`

		local caseB = if threshold >= 0 then `bit32_extract(readu{alignedWidth + 8}(b, byte), bit, {width})` else nil

		return caseA, caseB, true
	else
		return alignedRead(width), unalignedRead(width), false
	end
end

local function getWriteCallback(width: number, threshold: number)
	if width <= 24 or (threshold < 0 and width <= 32) then
		local alignedWidth = math.ceil(width / 8) * 8

		local caseA = if width ~= alignedWidth
			then `writeu{alignedWidth}(b, byte, bit32_replace(readu{alignedWidth}(b, byte), value, bit, {width}))`
			else `writeu{alignedWidth}(b, byte, value)`

		local caseB = if threshold >= 0
			then `writeu{alignedWidth + 8}(b, byte, bit32_replace(readu{alignedWidth + 8}(b, byte), value, bit, {width}))`
			else nil

		return caseA, caseB
	else
		return alignedWrite(width), unalignedWrite(width)
	end
end

local function getBitThreshold(width: number): number
	return 8 * math.ceil((width - 1) / 8) - width
end

local function generateRead(output)
	for width = 1, 53 do
		local body = Snippet.new()

		local bitThreshold = getBitThreshold(width)
		local alignedCase, unalignedCase, isSingleLine = getReadCallback(width, bitThreshold)

		if unalignedCase then
			if isSingleLine then
				body:Push("return if bit > ", if width > 24 then 0 else bitThreshold)
				body:Push("then ", unalignedCase):Indent()
				body:Push("else ", alignedCase):Indent()
			else
				body:Push("if bit > ", if width > 24 then 0 else bitThreshold, " then")
				body:Push(unalignedCase):Indent()
				body:Push("else")
				body:Push("return ", alignedCase):Indent()
				body:Push("end")
			end
		else
			body:Push("return ", alignedCase)
		end

		readCalls[width] = if bitThreshold > 0
			then tostring(body):gsub("^return ", "")
			else unalignedCase or alignedCase

		body:Insert(1, "local byte, bit = offset // 8, offset % 8")
		body:Indent()

		body:Insert(1, "function bitbuffer.readu", width, "(b: buffer, offset: number): number")
		body:Push("end")

		table.insert(output, tostring(body))
	end
end

local function generateWrite(output)
	for width = 1, 53 do
		local body = Snippet.new()

		local bitThreshold = getBitThreshold(width)
		local alignedCase, unalignedCase = getWriteCallback(width, bitThreshold)

		if unalignedCase then
			body:Push("if bit > ", if width > 24 then 0 else bitThreshold, " then")
			body:Push(unalignedCase):Indent()
			body:Push("else")
			body:Push(alignedCase):Indent()
			body:Push("end")
		else
			body:Push(alignedCase)
		end

		writeCalls[width] = if bitThreshold > 0 then tostring(body) else unalignedCase or alignedCase

		body:Insert(1, "local byte, bit = offset // 8, offset % 8")
		body:Indent()

		body:Insert(1, "function bitbuffer.writeu", width, "(b: buffer, offset: number, value: number)")
		body:Push("end")

		table.insert(output, tostring(body))
	end
end

local function finalise(output)
	local readLookup, writeLookup = {}, {}
	for width = 1, 53 do
		table.insert(readLookup, `bitbuffer.readu{width}`)
		table.insert(writeLookup, `bitbuffer.writeu{width}`)
	end

	local body = {}

	table.insert(body, `local unsignedRead, unsignedWrite =`)
	table.insert(body, `\t\{ {table.concat(readLookup, ", ")} \},`)
	table.insert(body, `\t\{ {table.concat(writeLookup, ", ")} \}`)
	table.insert(body, "")
	table.insert(body, GENERALISED_READ_WRITE)

	table.insert(output, table.concat(body, "\n"))
end

local function create()
	local output = {}
	table.insert(output, LOCALISED_FUNCTIONS)
	generateWrite(output)
	generateRead(output)
	finalise(output)
	return output
end

return create
