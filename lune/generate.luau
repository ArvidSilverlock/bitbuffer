local process = require("@lune/process")
local fs = require("@lune/fs")

local output = {}

-- stylua: ignore
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

local bitbuffer = {}]])

local function addSection(name, section, outputTable)
	local str = if type(section) == "function" then table.concat(section(addSection), "\n\n") else tostring(section)
	table.insert(outputTable or output, `do -- {name}\n\t{str:gsub("\n\t*", "%1\t")}\nend`)
end

local function writeMain()
	local main = require("./main/init.luau")
	addSection("uint", main.uint)
	addSection("int", main.int)
	addSection("float", main.float)
	addSection("string", main.string)
	addSection("other", main.other)
end

if process.args[1] then
	for _, argument in process.args do
		if argument == "main" then
			writeMain()
		else
			local callback = require(`./{argument}/init.luau`)
			addSection(argument, callback)
		end
	end
else
	local baseconversion = require("./baseconversion/init.luau")
	local editors = require("./editors/init.luau")

	writeMain()

	addSection("base conversion", baseconversion)
	addSection("editors", editors)
end

table.insert(output, "return bitbuffer")

local source = table.concat(output, "\n\n"):gsub("\n%s+\n", "\n\n")
fs.writeFile("lune/output.luau", source)
