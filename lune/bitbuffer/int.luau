local Snippet = require("../Snippet.luau")

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

local function generateRead(addSection, tsOutput)
	local output = {}
	for width = 2, 52 do
		local body = Snippet.new()
		local a, b = 2 ^ width, 2 ^ (width - 1)

		local alignedCallback = BUILT_IN_READ[width]
		local unalignedCallback = `( bitbuffer.readu{width}(b, byte, bit) + {b} ) % {a} - {b}`

		if alignedCallback then
			body:Push("return if bit > 0")
			body:Push("\tthen ", unalignedCallback)
			body:Push("\telse ", alignedCallback, "(b, byte)")
		else
			body:Push("return ", unalignedCallback)
		end

		body:Indent()
		body:Insert(1, "--- Reads a ", width, " bit signed integer [", -b, ", ", b - 1, "]")
		body:Insert(2, "function bitbuffer.readi", width, "(b: buffer, byte: number, bit: number): number")
		body:Push("end")

		tsOutput:Push("readi", width, ": read<number>;")
		table.insert(output, tostring(body))
	end
	return output
end

local function generateWrite(addSection, tsOutput)
	local output = {}
	for width = 2, 52 do
		local body = Snippet.new()
		local a, b = 2 ^ width, 2 ^ (width - 1)

		local alignedCallback = BUILT_IN_WRITE[width]
		local unalignedCallback = `bitbuffer.writeu{width}(b, byte, bit, (value + {a}) % {a})`

		if alignedCallback then
			body:Push("if bit > 0 then")
			body:Push("\t", unalignedCallback)
			body:Push("else")
			body:Push("\t", alignedCallback, "(b, byte, value)")
			body:Push("end")
		else
			body:Push(unalignedCallback)
		end

		body:Indent()
		body:Insert(1, "--- Writes a ", width, " bit signed integer [", -b, ", ", b - 1, "]")
		body:Insert(2, "function bitbuffer.writei", width, "(b: buffer, byte: number, bit: number, value: number)")
		body:Push("end")

		tsOutput:Push("writei", width, ": write<number>;")
		table.insert(output, tostring(body))
	end
	return output
end

local function finalise(output, tsOutput)
	local readLookup, writeLookup = {}, {}
	for width = 2, 52 do
		table.insert(readLookup, `bitbuffer.readi{width}`)
		table.insert(writeLookup, `bitbuffer.writei{width}`)
	end

	local body = Snippet.new()

	body:Push("bitbuffer.readi = { nil :: any, ", table.concat(readLookup, ", "), " }")
	body:Push("bitbuffer.writei = { nil :: any, ", table.concat(writeLookup, ", "), " }")

	tsOutput:Push("readi: Array<read<number>>")
	tsOutput:Push("writei: Array<write<number>>")
	tsOutput:Push("")

	table.insert(output, tostring(body))
end

local function create(addSection, tsOutput)
	local output = {}
	table.insert(output, LOCALISED_FUNCTIONS)

	addSection("write", generateWrite, output, tsOutput)
	tsOutput:Push("")
	addSection("read", generateRead, output, tsOutput)
	tsOutput:Push("")
	finalise(output, tsOutput)
	tsOutput:Push("")

	return output
end

return create
