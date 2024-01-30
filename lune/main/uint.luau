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

local function indent(str: string, amount: number): string
	local tab = string.rep("\t", amount)
	return tab .. str:gsub("\n", "\n" .. tab)
end

local function alignedRead(width: number)
	local lines = {}

	local position, chunkWidth = 0, math.min(width, 32)

	local band = if width ~= 32 then string.format(" %% 0x%x", 2 ^ chunkWidth) else ""
	table.insert(lines, `readu32(b, byte){band}`)

	while true do
		position += chunkWidth
		chunkWidth = math.min(width - position, 32)
		if chunkWidth == 0 then
			break
		end

		local multiplier = string.format(" * 0x%x", 2 ^ position)
		local bound = string.format(" %% 0x%x", 2 ^ chunkWidth)
		local offset = ` + {position / 8}`

		local alignedWidth = math.ceil(chunkWidth / 8) * 8
		if chunkWidth == alignedWidth then
			table.insert(lines, `\t+ readu{alignedWidth}(b, byte{offset}){multiplier}`)
		else
			table.insert(lines, `\t+ readu{alignedWidth}(b, byte{offset}){bound}{multiplier}`)
		end
	end

	return table.concat(lines, "\n")
end

local function unalignedRead(width: number)
	local lines = {}

	local chunkCount = math.ceil(width / 24)

	local position, chunkWidth = 0, math.min(width, 24)
	table.insert(lines, `return bit32_extract(readu32(b, byte), bit, 24)`)

	for _ = 2, chunkCount do
		position += chunkWidth
		chunkWidth = math.min(width - position, 24)

		local multiplier = string.format(" * 0x%x", 2 ^ position)
		local offset = ` + {position / 8}`

		if chunkWidth == 24 then
			table.insert(lines, `\t+ bit32_extract(readu32(b, byte{offset}), bit, {chunkWidth}){multiplier}`)
		else
			local read = `{readCalls[chunkWidth]:gsub("byte", `byte{offset}`)}`
			if read:match("^if") then
				table.insert(lines, `\t+ (\n\t\t{read:gsub("\n", "\n\t\t")}\n\t){multiplier}`)
			else
				table.insert(lines, `\t+ {read}{multiplier}`)
			end
		end
	end

	return table.concat(lines, "\n")
end

local function alignedWrite(width: number)
	local position, chunkWidth = 0, math.min(width, 32)
	local lines = {}

	table.insert(lines, `writeu32(b, byte, value)`)

	while true do
		position += chunkWidth
		chunkWidth = math.min(width - position, 32)
		if chunkWidth == 0 then
			break
		end

		local alignedWidth = math.ceil(chunkWidth / 8) * 8
		local divisor = string.format(" // 0x%x", 2 ^ position)

		if chunkWidth ~= alignedWidth then
			local replacement = `bit32_replace(readu{alignedWidth}(b, byte), value{divisor}, 0, {chunkWidth})`
			table.insert(lines, "byte += 4")
			table.insert(lines, `writeu{alignedWidth}(b, byte, {replacement})`)
		else
			table.insert(lines, `writeu{alignedWidth}(b, byte + 4, value{divisor})`)
		end
	end

	return table.concat(lines, "\n")
end

local function unalignedWrite(width: number)
	local position, chunkWidth = 0, 24
	local lines = {}

	table.insert(lines, "writeu32(b, byte, bit32_replace(readu32(b, byte), value, bit, 24))")

	while true do
		position += chunkWidth
		chunkWidth = math.min(width - position, 24)
		if chunkWidth == 0 then
			break
		end

		local divisor = string.format(" // 0x%x", 2 ^ position)
		table.insert(lines, "byte += 3")

		if chunkWidth == 24 then
			table.insert(lines, `writeu32(b, byte, bit32_replace(readu32(b, byte), value{divisor}, bit, 24))`)
		else
			table.insert(lines, (writeCalls[chunkWidth]:gsub("value", `value{divisor}`)))
		end
	end

	return table.concat(lines, "\n")
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
		local body = {}

		local bitThreshold = getBitThreshold(width)
		local alignedCase, unalignedCase, isSingleLine = getReadCallback(width, bitThreshold)

		if unalignedCase then
			if isSingleLine then
				table.insert(body, `\treturn if bit > {if width > 24 then 0 else bitThreshold}`)
				table.insert(body, indent("then " .. unalignedCase, 2))
				table.insert(body, indent("else " .. alignedCase, 2))
			else
				table.insert(body, `\tif bit > {if width > 24 then 0 else bitThreshold} then`)
				table.insert(body, indent(unalignedCase, 2))
				table.insert(body, "\telse")
				table.insert(body, indent("return " .. alignedCase, 2))
				table.insert(body, "\tend")
			end
		else
			for index, line in alignedCase:split("\n") do
				table.insert(body, `\t{if index == 1 then "return " else ""}{line}`)
			end
		end

		readCalls[width] = if bitThreshold > 0
			then table.concat(body, "\n"):gsub("\n\t", "\n"):gsub("^\t", ""):gsub("^return ", "")
			else unalignedCase or alignedCase

		table.insert(body, 1, `function bitbuffer.readu{width}(b: buffer, offset: number): number`)
		table.insert(body, 2, `\tlocal byte, bit = offset // 8, offset % 8`)
		table.insert(body, "end")

		table.insert(output, table.concat(body, "\n"))
	end
end

local function generateWrite(output)
	for width = 1, 53 do
		local body = {}

		local bitThreshold = getBitThreshold(width)
		local alignedCase, unalignedCase = getWriteCallback(width, bitThreshold)

		if unalignedCase then
			table.insert(body, `\tif bit > {if width > 24 then 0 else bitThreshold} then`)
			table.insert(body, indent(unalignedCase, 2))
			table.insert(body, `\telse`)
			table.insert(body, indent(alignedCase, 2))
			table.insert(body, "\tend")
		else
			table.insert(body, indent(alignedCase, 1))
		end

		writeCalls[width] = if bitThreshold > 0
			then table.concat(body, "\n"):gsub("\n\t", "\n"):gsub("^\t", "")
			else unalignedCase or alignedCase

		table.insert(body, 1, `function bitbuffer.writeu{width}(b: buffer, offset: number, value: number)`)
		table.insert(body, 2, `\tlocal byte, bit = offset // 8, offset % 8`)
		table.insert(body, "end")

		table.insert(output, table.concat(body, "\n"))
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
