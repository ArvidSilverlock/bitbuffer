local Snippet = require("../Snippet.luau")

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

	local body = Snippet.new()

	local bound = if width < 32 then string.format(" %% 0x%x", 2 ^ width) else ""
	body:Push(`buffer.readu32(b, byte){bound}`, 1)

	for index = 1, chunkCount - 1 do
		local position, bytePosition = index * 32, index * 4
		local chunkWidth = math.min(width - position, 32)

		local multiplier = string.format(" * 0x%x", 2 ^ position)
		local bound = string.format(" %% 0x%x", 2 ^ chunkWidth)

		local alignedWidth = math.ceil(chunkWidth / 8) * 8
		local readCallback = BYTE_ALIGNED_READ[alignedWidth]

		if chunkWidth == alignedWidth then
			body:Push(`+ {readCallback}(b, byte + {bytePosition}){multiplier}`)
		else
			body:Push(`+ {readCallback}(b, byte + {bytePosition}){bound}{multiplier}`)
		end
	end

	return tostring(body)
end

local function unalignedRead(width: number)
	local chunkCount = math.ceil(width / 24)
	local position, chunkWidth = 0, math.min(width, 24)

	local body = Snippet.new()
	body:Push("bit32.extract(buffer.readu32(b, byte), bit, 24)", 1)

	for _ = 2, chunkCount do
		position += chunkWidth
		chunkWidth = math.min(width - position, 24)

		local multiplier = string.format(" * 0x%x", 2 ^ position)
		local offset = ` + {position / 8}`

		if chunkWidth == 24 then
			body:Push(`+ bit32.extract(buffer.readu32(b, byte{offset}), bit, {chunkWidth}){multiplier}`)
		else
			local chunkSnippet = tostring(Snippet.get(`readu{chunkWidth}`))
			if chunkSnippet:match("^if bit > 0") then
				chunkSnippet = tostring(Snippet.get(`unalignedreadu{chunkWidth}`))
			end

			local read = tostring(chunkSnippet):gsub("byte", `byte{offset}`)
			if read:match("^if") then
				body:Push("+ (", 1, read, -1, `){multiplier}`)
			else
				body:Push(`+ {read}{multiplier}`)
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
			body:Push(`{writeCallback}(b, byte, {replacement})`)
		elseif index == 0 then
			body:Push(`{writeCallback}(b, byte, value{divisor})`)
		else
			body:Push(`{writeCallback}(b, byte + 4, value{divisor})`)
		end
	end

	return tostring(body)
end

local function unalignedWrite(width: number)
	local chunkCount = math.ceil(width / 24)

	local body = Snippet.new()
	body:Push("buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value, bit, 24))")

	for index = 1, chunkCount - 1 do
		local position = 24 * index
		local chunkWidth = math.min(width - position, 24)

		local divisor = string.format(" // 0x%x", 2 ^ position)
		body:Push("byte += 3")

		if chunkWidth == 24 then
			body:Push(`buffer.writeu32(b, byte, bit32.replace(buffer.readu32(b, byte), value{divisor}, bit, 24))`)
		else
			local chunkSnippet = tostring(Snippet.get(`writeu{chunkWidth}`))
			if chunkSnippet:match("^if bit > 0") then
				chunkSnippet = tostring(Snippet.get(`unalignedwriteu{chunkWidth}`))
			end

			body:Push(chunkSnippet:gsub("value", `value{divisor}`))
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

		return caseA, caseB
	else
		return alignedRead(width), unalignedRead(width)
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
		local alignedCase, unalignedCase = getReadCallback(width, bitThreshold)

		local functionName = `readu{width}`

		local function createSnippet(variable: string)
			local snippet = Snippet.new(if variable then functionName else nil)
			local assignment = if variable == nil then "return " else ""

			Snippet.new(`aligned{functionName}`):Push(alignedCase)

			if unalignedCase then
				-- stylua: ignore
				snippet:Push(
					`{assignment}if bit > {if width > 24 then 0 else bitThreshold}`, 1,
						`then {unalignedCase}`,
						`else {alignedCase}`, -1
				)

				Snippet.new(`unaligned{functionName}`):Push(unalignedCase)
			else
				snippet:Push(`{assignment}{alignedCase}`)
			end

			return snippet
		end

		local body = createSnippet(nil)
		createSnippet("value") -- can be retrieved using `Snippet.get("readu<n>")`

		local comment = `Reads a {width} bit unsigned integer [0, {2 ^ width - 1}]`

		-- stylua: ignore
		luau:Push(
			`--- {comment}`,
			`function bitbuffer.{functionName}(b: buffer, byte: number, bit: number): number`, 1,
				body,
			-1, "end",
			if width < 53 then "" else nil
		)

		-- stylua: ignore
		typescript
			:Push(`/** {comment} */`)
			:Push(`readu{width}: read<number>;`)
	end

	typescript:Break()
end

local function generateWrite(luau, typescript)
	for width = 1, 53 do
		local bitThreshold = getBitThreshold(width)
		local alignedCase, unalignedCase = getWriteCallback(width, bitThreshold)

		local functionName = `writeu{width}`
		local body = Snippet.new(functionName)

		Snippet.new(`aligned{functionName}`):Push(alignedCase)

		if unalignedCase then
			-- stylua: ignore
			body:Push(
				`if bit > {if width > 24 then 0 else bitThreshold} then`, 1,
					unalignedCase,
				-1, "else", 1,
					alignedCase,
				-1, "end"
			)

			Snippet.new(`unaligned{functionName}`):Push(unalignedCase)
		else
			body:Push(alignedCase)
		end

		local comment = `Writes a {width} bit unsigned integer [0, {2 ^ width - 1}]`

		-- stylua: ignore
		luau:Push(
			`--- {comment}`,
			`function bitbuffer.{functionName}(b: buffer, byte: number, bit: number, value: number)`, 1,
				body,
			-1, "end",
			if width < 53 then "" else nil
		)

		-- stylua: ignore
		typescript:Push(
			`/** {comment} */`,
			`writeu{width}: write<number>;`
		)
	end

	typescript:Break()
end

local function finalise(luau, typescript)
	local readLookup, writeLookup = {}, {}
	for width = 1, 53 do
		table.insert(readLookup, `bitbuffer.readu{width}`)
		table.insert(writeLookup, `bitbuffer.writeu{width}`)
	end

	-- stylua: ignore
	luau:Push(
		`bitbuffer.readu = \{ {table.concat(readLookup, ", ")} \}`,
		`bitbuffer.writeu = \{ {table.concat(writeLookup, ", ")} \}`
	)

	-- stylua: ignore
	typescript:Push(
		"readu: Array<read<number>>",
		"writeu: Array<write<number>>",
		""
	)
end

return function(luau, typescript)
	luau:LuauBlock("write", generateWrite, typescript)
		:Break()
		:LuauBlock("read", generateRead, typescript)
		:Break()
		:Call(finalise, typescript)
end
