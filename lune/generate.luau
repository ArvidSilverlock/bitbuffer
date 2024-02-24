local process = require("@lune/process")
local fs = require("@lune/fs")

local output = {}
local tsOutput = {}

-- stylua: ignore start
table.insert(output, [[--!native
--!optimize 2
--!strict

-- stylua: ignore start
---@diagnostic disable: undefined-type

local readu8 = buffer.readu8
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
local bit32_extract = bit32.extract

--- @class bitbuffer
local bitbuffer = {}]])

table.insert(tsOutput, [[type write<T> = (b: buffer, byte: number, bit: number, value: T) => void
type read<T> = (b: buffer, byte: number, bit: number) => T]])
-- stylua: ignore end

local function addSection(name, section, outputTable, ...)
	local luauString, tsString
	if type(section) == "function" then
		luauString, tsString = section(addSection, ...)
		luauString = table.concat(luauString, "\n\n")
	else
		luauString = tostring(section)
	end

	table.insert(outputTable or output, `do -- {name}\n\t{luauString:gsub("\n\t*", "%1\t")}\nend`)
	if tsString then
		table.insert(tsOutput, tsString)
	end
end

local editors = require("./editors/init.luau")
local main = require("./bitbuffer/init.luau")

addSection("bitbuffer", main)
addSection("editors", editors)

table.insert(output, "return bitbuffer")
table.insert(tsOutput, "declare const bitbuffer: bitbuffer;\nexport = bitbuffer")

local luauSource = table.concat(output, "\n\n"):gsub("\n%s+\n", "\n\n")
fs.writeFile("./src/init.luau", luauSource)

local tsSource = table.concat(tsOutput, "\n\n"):gsub("\n%s+\n", "\n\n")
fs.writeFile("./src/index.d.ts", tsSource)

require("./test.luau")
