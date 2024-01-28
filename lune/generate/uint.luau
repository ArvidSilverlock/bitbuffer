local READ_FUNCTION_DEFINITION = "function bitbuffer.readu%d(b: buffer, byte: number, bit: number): number"
local WRITE_FUNCTION_DEFINITION = "function bitbuffer.writeu%d(b: buffer, byte: number, bit: number, value: number)"

local GENERALISED_READ_WRITE = [[function bitbuffer.readu(b: buffer, offset: number, width: number): number
	return unsignedRead[width](b, offset // 8, offset % 8)
end

function bitbuffer.writeu(b: buffer, offset: number, value: number, width: number)
	unsignedWrite[width](b, offset // 8, offset % 8, value)
end]]

local READ_CALLBACK_FORMATS = {
	[8] = "buffer.readu8(b, byte)",
	[16] = "buffer.readu16(b, byte)",
	[24] = "readu24(b, byte)",
	[32] = "buffer.readu32(b, byte)",
}

local WRITE_CALLBACK_FORMATS = {
	[8] = "buffer.writeu8(b, byte, <VALUE>)",
	[16] = "buffer.writeu16(b, byte, <VALUE>)",
	[24] = "writeu24(b, byte, <VALUE>)",
	[32] = "buffer.writeu32(b, byte, <VALUE>)",
}

local function alignedRead(width: number)
	local lines = {}

	local position, chunkWidth = 0, math.min(width, 32)

	local band = if width ~= 32 then string.format(" %% 0x%x", 2 ^ chunkWidth) else ""
	table.insert(lines, `buffer.readu32(b, byte){band}`)

	while true do
		position += chunkWidth
		chunkWidth = math.min(width - position, 32)
		if chunkWidth == 0 then
			break
		end

		local multiplier = string.format(" * 0x%x", 2 ^ position)
		local band = string.format(" %% 0x%x", 2 ^ chunkWidth)
		local offset = ` + {position / 8}`

		local alignedWidth = math.ceil(chunkWidth / 8) * 8

		if chunkWidth == alignedWidth then
			table.insert(lines, `\t+ buffer.readu{alignedWidth}(b, byte{offset}){multiplier}`)
		else
			local readCallback = READ_CALLBACK_FORMATS[alignedWidth]:gsub("byte", `byte{offset}`)
			table.insert(lines, `\t+ {readCallback}{band}{multiplier}`)
		end
	end

	return table.concat(lines, "\n")
end

local function unalignedRead(width: number)
	local lines = {}

	local position, chunkWidth = 0, math.min(width, 24)
	table.insert(lines, `bitbuffer.readu24(b, byte, bit)`)

	while true do
		position += chunkWidth
		chunkWidth = math.min(width - position, 24)
		if chunkWidth == 0 then
			break
		end

		local multiplier = string.format(" * 0x%x", 2 ^ position)
		table.insert(lines, `\t+ bitbuffer.readu{chunkWidth}(b, byte + {position / 8}, bit){multiplier}`)
	end

	return table.concat(lines, "\n")
end

local function alignedWrite(width: number)
	local position, chunkWidth = 0, math.min(width, 32)
	local lines = {}

	table.insert(lines, `buffer.writeu32(b, byte, value)`)

	while true do
		position += chunkWidth
		chunkWidth = math.min(width - position, 32)
		if chunkWidth == 0 then
			break
		end

		table.insert(lines, "byte += 4")

		local alignedWidth = math.ceil(chunkWidth / 8) * 8
		local writeCallback = WRITE_CALLBACK_FORMATS[alignedWidth]

		local divisor = string.format(" // 0x%x", 2 ^ position)

		if alignedWidth ~= chunkWidth then
			local replacement = `bit32.replace({READ_CALLBACK_FORMATS[alignedWidth]}, value{divisor}, 0, {chunkWidth})`
			local write = writeCallback:gsub("<VALUE>", replacement)
			table.insert(lines, write)
		else
			local write = writeCallback:gsub("<VALUE>", "value" .. divisor)
			table.insert(lines, write)
		end
	end

	return table.concat(lines, "\n")
end

local function unalignedWrite(width: number)
	local position, chunkWidth = 0, 24
	local lines = {}

	table.insert(lines, `bitbuffer.writeu24(b, byte, bit, value)`)

	while true do
		position += chunkWidth
		chunkWidth = math.min(width - position, 24)
		if chunkWidth == 0 then
			break
		end

		local divisor = string.format(" / 0x%x", 2 ^ position)
		table.insert(lines, `bitbuffer.writeu{chunkWidth}(b, byte + {position / 8}, bit, value{divisor})`)
	end

	return table.concat(lines, "\n")
end

local function getReadCallback(width: number, threshold: number)
	if width <= 24 or (threshold < 0 and width <= 32) then
		local alignedWidth = math.ceil(width / 8) * 8

		local caseA
		if width ~= alignedWidth then
			local alignedRead = READ_CALLBACK_FORMATS[alignedWidth]
			caseA = `bit32.extract({alignedRead}, bit, {width})`
		else
			caseA = READ_CALLBACK_FORMATS[width]:gsub("<VALUE>", "value")
		end

		local caseB
		if threshold >= 0 then
			local alignedRead = READ_CALLBACK_FORMATS[alignedWidth + 8]
			caseB = `bit32.extract({alignedRead}, bit, {width})`
		end

		return caseA, caseB
	else
		return alignedRead(width), unalignedRead(width)
	end
end

local function getWriteCallback(width: number, threshold: number)
	if width <= 24 or (threshold < 0 and width <= 32) then
		local alignedWidth = math.ceil(width / 8) * 8

		local caseA
		if width ~= alignedWidth then
			local alignedRead = READ_CALLBACK_FORMATS[alignedWidth]
			local alignedWrite = WRITE_CALLBACK_FORMATS[alignedWidth]
			caseA = alignedWrite:gsub("<VALUE>", `bit32.replace({alignedRead}, value, bit, {width})`)
		else
			caseA = WRITE_CALLBACK_FORMATS[width]:gsub("<VALUE>", "value")
		end

		local caseB
		if threshold >= 0 then
			local alignedRead = READ_CALLBACK_FORMATS[alignedWidth + 8]
			local alignedWrite = WRITE_CALLBACK_FORMATS[alignedWidth + 8]
			caseB = alignedWrite:gsub("<VALUE>", `bit32.replace({alignedRead}, value, bit, {width})`)
		end

		return caseA, caseB
	else
		return alignedWrite(width), unalignedWrite(width)
	end
end

local function generateRead(output)
	for width = 1, 53 do
		local body = {}

		local bitThreshold = 8 * math.ceil((width - 1) / 8) - width
		local readAligned, readUnaligned = getReadCallback(width, bitThreshold)

		table.insert(body, READ_FUNCTION_DEFINITION:format(width))
		if readUnaligned then
			table.insert(body, `\treturn if bit > {if width > 24 then 0 else bitThreshold}`)
			for index, line in readUnaligned:split("\n") do
				table.insert(body, `\t\t{if index == 1 then "then " else ""}{line}`)
			end
			for index, line in readAligned:split("\n") do
				table.insert(body, `\t\t{if index == 1 then "else " else ""}{line}`)
			end
		else
			for index, line in readAligned:split("\n") do
				table.insert(body, `\t{if index == 1 then "return " else ""}{line}`)
			end
		end

		table.insert(body, "end")
		table.insert(output, table.concat(body, "\n"))
	end
end

local function generateWrite(output)
	for width = 1, 53 do
		local body = {}

		local bitThreshold = 8 * math.ceil((width - 1) / 8) - width
		local readAligned, readUnaligned = getWriteCallback(width, bitThreshold)

		table.insert(body, WRITE_FUNCTION_DEFINITION:format(width))
		if readUnaligned then
			table.insert(body, `\tif bit > {if width > 24 then 0 else bitThreshold} then`)
			for _, line in readUnaligned:split("\n") do
				table.insert(body, `\t\t{line}`)
			end
			table.insert(body, `\telse`)
			for _, line in readAligned:split("\n") do
				table.insert(body, `\t\t{line}`)
			end
			table.insert(body, `\tend`)
		else
			for _, line in readAligned:split("\n") do
				table.insert(body, `\t{line}`)
			end
		end

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

return {
	read = generateRead,
	write = generateWrite,
	finalise = finalise,
}
