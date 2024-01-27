local READ_FUNCTION_DEFINITION = "function bitbuffer.readi%d(b: buffer, byte: number, bit: number): number"
local WRITE_FUNCTION_DEFINITION = "function bitbuffer.writei%d(b: buffer, byte: number, bit: number, value: number)"

local GENERALISED_READ_WRITE = [[function bitbuffer.readi(b: buffer, offset: number, width: number): number
	return signedRead[width](b, offset // 8, offset % 8)
end

function bitbuffer.writei(b: buffer, offset: number, width: number, value: number)
	signedWrite[width](b, offset // 8, offset % 8, value)
end]]

local BUILT_IN_READ = {
	[8] = "buffer.readi8",
	[16] = "buffer.readi16",
	[32] = "buffer.readi32",
}

local BUILT_IN_WRITE = {
	[8] = "buffer.writei8",
	[16] = "buffer.writei16",
	[32] = "buffer.writei32",
}

local function generateRead(output)
	for width = 2, 52 do
		local body = {}
		local a, b = 2 ^ width, 2 ^ (width - 1)

		local alignedCallback = BUILT_IN_READ[width]
		local unalignedCallback = `( bitbuffer.readu{width}(b, byte, bit) + {b} ) % {a} - {b}`

		table.insert(body, READ_FUNCTION_DEFINITION:format(width))
		if alignedCallback then
			table.insert(body, "\treturn if bit > 0")
			table.insert(body, `\t\tthen {unalignedCallback}`)
			table.insert(body, `\t\telse {alignedCallback}(b, byte, bit)`)
		else
			table.insert(body, `\treturn {unalignedCallback}`)
		end
		table.insert(body, "end")

		table.insert(output, table.concat(body, "\n"))
	end
end

local function generateWrite(output)
	for width = 2, 52 do
		local body = {}
		local a = 2 ^ width

		local alignedCallback = BUILT_IN_WRITE[width]
		local unalignedCallback = `bitbuffer.writeu{width}(b, byte, bit, (value + {a}) % {a})`

		table.insert(body, WRITE_FUNCTION_DEFINITION:format(width))
		if alignedCallback then
			table.insert(body, "\tif bit > 0 then")
			table.insert(body, `\t\t{unalignedCallback}`)
			table.insert(body, "\telse")
			table.insert(body, `\t\t{alignedCallback}(b, byte, bit)`)
			table.insert(body, "\tend")
		else
			table.insert(body, `\treturn {unalignedCallback}`)
		end
		table.insert(body, "end")

		table.insert(output, table.concat(body, "\n"))
	end
end

local function finalise(output)
	local readLookup, writeLookup = {}, {}
	for width = 1, 53 do
		table.insert(readLookup, `bitbuffer.readi{width}`)
		table.insert(writeLookup, `bitbuffer.writei{width}`)
	end

	local body = {}

	table.insert(body, `-- stylua: ignore`)
	table.insert(body, `local signedRead, signedWrite =`)
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
