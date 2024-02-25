local Snippet = require("../Snippet/init.luau")

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

local function generateRead(addSection, tsOutput)
	local output = {}
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

		body:Indent()

		body:Insert(1, "--- Writes a ", width, " bit unsigned integer [0, ", 2 ^ width - 1, "]")
		body:Insert(2, "function bitbuffer.readu", width, "(b: buffer, byte: number, bit: number): number")
		body:Push("end")

		tsOutput:Push("readu", width, ": read<number>;")
		table.insert(output, tostring(body))
	end
	return output
end

local function generateWrite(addSection, tsOutput)
	local output = {}
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

		body:Indent()

		body:Insert(1, "--- Writes a ", width, " bit unsigned integer [0, ", 2 ^ width - 1, "]")
		body:Insert(2, "function bitbuffer.writeu", width, "(b: buffer, byte: number, bit: number, value: number)")
		body:Push("end")

		tsOutput:Push("writeu", width, ": write<number>;")
		table.insert(output, tostring(body))
	end
	return output
end

local function finalise(output, tsOutput)
	local readLookup, writeLookup = {}, {}
	for width = 1, 53 do
		table.insert(readLookup, `bitbuffer.readu{width}`)
		table.insert(writeLookup, `bitbuffer.writeu{width}`)
	end

	local body = {}

	table.insert(body, `bitbuffer.readu = \{ {table.concat(readLookup, ", ")} \}`)
	table.insert(body, `bitbuffer.writeu = \{ {table.concat(writeLookup, ", ")} \}`)

	tsOutput:Push("readu: Array<read<number>>")
	tsOutput:Push("writeu: Array<write<number>>")
	tsOutput:Push("")

	table.insert(output, table.concat(body, "\n"))
end

local function create(addSection, tsOutput)
	local output = {}

	addSection("write", generateWrite, output, tsOutput)
	tsOutput:Push("")
	addSection("read", generateRead, output, tsOutput)
	tsOutput:Push("")
	finalise(output, tsOutput)
	tsOutput:Push("")

	return output
end

return create
