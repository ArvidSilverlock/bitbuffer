local int = require("./int.luau")
local uint = require("./uint.luau")
local float = require("./float.luau")

local function append(output)
	-- stylua: ignore
	table.insert(output, [[local U24_BUFFER = buffer.create(4)

local function readu24(b: buffer, offset: number)
	buffer.copy(U24_BUFFER, 0, b, offset, 3)
	return buffer.readu32(U24_BUFFER, 0)
end
	
local function writeu24(b: buffer, offset: number, value: number)
	buffer.writeu32(U24_BUFFER, 0, value)
	buffer.copy(b, offset, U24_BUFFER, 0, 3)
end]])

	uint.read(output)
	uint.write(output)

	int.read(output)
	int.write(output)

	float.read(output)
	float.write(output)

	uint.finalise(output)
	int.finalise(output)
end

return append
