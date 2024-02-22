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

local function generateRead()
	local output = {}
	for width = 2, 52 do
		local body = Snippet.new()
		local a, b = 2 ^ width, 2 ^ (width - 1)

		local alignedCallback = BUILT_IN_READ[width]
		local unalignedCallback = `( bitbuffer.readu{width}(b, offset) + {b} ) % {a} - {b}`

		if alignedCallback then
			body:Push("return if offset % 8 > 0")
			body:Push("\tthen ", unalignedCallback)
			body:Push("\telse ", alignedCallback, "(b, offset // 8)")
		else
			body:Push("return ", unalignedCallback)
		end

		body:Indent()
		body:Insert(1, "--- Reads a ", width, " bit signed integer [", -a, ", ", a - 1, "]")
		body:Insert(2, "function bitbuffer.readi", width, "(b: buffer, offset: number): number")
		body:Push("end")

		table.insert(output, tostring(body))
	end
	return output
end

local function generateWrite()
	local output = {}
	for width = 2, 52 do
		local body = Snippet.new()
		local a = 2 ^ width

		local alignedCallback = BUILT_IN_WRITE[width]
		local unalignedCallback = `bitbuffer.writeu{width}(b, offset, (value + {a}) % {a})`

		if alignedCallback then
			body:Push("if offset % 8 > 0 then")
			body:Push("\t", unalignedCallback)
			body:Push("else")
			body:Push("\t", alignedCallback, "(b, offset // 8, value)")
			body:Push("end")
		else
			body:Push(unalignedCallback)
		end

		body:Indent()
		body:Insert(1, "--- Writes a ", width, " bit signed integer [", -a, ", ", a - 1, "]")
		body:Insert(2, "function bitbuffer.writei", width, "(b: buffer, offset: number, value: number)")
		body:Push("end")

		table.insert(output, tostring(body))
	end
	return output
end

local function finalise(output)
	local readLookup, writeLookup = {}, {}
	for width = 2, 52 do
		table.insert(readLookup, `bitbuffer.readi{width}`)
		table.insert(writeLookup, `bitbuffer.writei{width}`)
	end

	local body = Snippet.new()

	body:Push("bitbuffer.readi = { nil :: any, ", table.concat(readLookup, ", "), " }")
	body:Push("bitbuffer.writei = { nil :: any, ", table.concat(writeLookup, ", "), " }")

	table.insert(output, tostring(body))
end

local function create(addSection)
	local output = {}
	table.insert(output, LOCALISED_FUNCTIONS)

	addSection("write", generateWrite, output)
	addSection("read", generateRead, output)

	finalise(output)
	return output
end

return create
