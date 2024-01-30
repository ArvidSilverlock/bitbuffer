local GENERALISED_READ_WRITE = [[function bitbuffer.readi(b: buffer, offset: number, width: number): number
	return signedRead[width](b, offset)
end

function bitbuffer.writei(b: buffer, offset: number, value: number, width: number)
	signedWrite[width](b, offset, value)
end]]

local LOCALISED_FUNCTIONS = [[local readi8 = buffer.readi8
local readi16 = buffer.readi16
local readi32 = buffer.readi32

local writei8 = buffer.writei8
local writei16 = buffer.writei16
local writei32 = buffer.writei32]]

local BUILT_IN_READ = {
	[8] = "readi8",
	[16] = "readi16",
	[32] = "readi32",
}

local BUILT_IN_WRITE = {
	[8] = "writei8",
	[16] = "writei16",
	[32] = "writei32",
}

local function generateRead(output)
	for width = 2, 52 do
		local body = {}
		local a, b = 2 ^ width, 2 ^ (width - 1)

		local alignedCallback = BUILT_IN_READ[width]
		local unalignedCallback = `( bitbuffer.readu{width}(b, offset) + {b} ) % {a} - {b}`

		table.insert(body, `function bitbuffer.readi{width}(b: buffer, offset: number): number`)
		if alignedCallback then
			table.insert(body, "\treturn if offset % 8 > 0")
			table.insert(body, `\t\tthen {unalignedCallback}`)
			table.insert(body, `\t\telse {alignedCallback}(b, offset // 8)`)
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
		local unalignedCallback = `bitbuffer.writeu{width}(b, offset, (value + {a}) % {a})`

		table.insert(body, `function bitbuffer.writei{width}(b: buffer, offset: number, value: number)`)
		if alignedCallback then
			table.insert(body, "\tif offset % 8 > 0 then")
			table.insert(body, `\t\t{unalignedCallback}`)
			table.insert(body, "\telse")
			table.insert(body, `\t\t{alignedCallback}(b, offset // 8, value)`)
			table.insert(body, "\tend")
		else
			table.insert(body, `\t{unalignedCallback}`)
		end
		table.insert(body, "end")

		table.insert(output, table.concat(body, "\n"))
	end
end

local function finalise(output)
	local readLookup, writeLookup = {}, {}
	for width = 2, 52 do
		table.insert(readLookup, `bitbuffer.readi{width}`)
		table.insert(writeLookup, `bitbuffer.writei{width}`)
	end

	local body = {}

	table.insert(body, `local signedRead, signedWrite =`)
	table.insert(body, `\t\{ nil :: any, {table.concat(readLookup, ", ")} \},`)
	table.insert(body, `\t\{ nil :: any, {table.concat(writeLookup, ", ")} \}`)
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
