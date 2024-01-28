local int = require("./generate/int.luau")
local uint = require("./generate/uint.luau")
local float = require("./generate/float.luau")

local fs = require("@lune/fs")

local output = {}

local function append(value)
	table.insert(output, value)
end

append([[--!native
--!optimize 2
--!strict
-- stylua: ignore start

local bitbuffer = {}

local U24_BUFFER = buffer.create(4)

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

append("return bitbuffer")

local outputString = table.concat(output, "\n\n"):gsub("\n\t+\n", "\n\n")
fs.writeFile("lune/output.luau", outputString)
