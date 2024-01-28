local process = require("@lune/process")
local fs = require("@lune/fs")

local output = {}

-- stylua: ignore
table.insert(output, [[--!native
--!optimize 2
--!strict
-- stylua: ignore start

local U24_BUFFER = buffer.create(4)

local function readu24(b: buffer, offset: number)
	buffer.copy(U24_BUFFER, 0, b, offset, 3)
	return buffer.readu32(U24_BUFFER, 0)
end
	
local function writeu24(b: buffer, offset: number, value: number)
	buffer.writeu32(U24_BUFFER, 0, value)
	buffer.copy(b, offset, U24_BUFFER, 0, 3)
end

local bitbuffer = {}]])

local function addSection(name, generator)
	local section = {}
	generator(section)

	local str = table.concat(section, "\n\n")
	table.insert(output, `do -- {name}\n\t{str:gsub("\n", "\n\t")}\nend`)
end

if process.args[1] then
	for _, argument in process.args do
		local callback = require(`./{argument}/init.lua`)
		callback(output)
	end
else
	local main = require(`./main/init.lua`)
	local baseconversion = require(`./baseconversion/init.lua`)
	local reader = require(`./reader/init.lua`)
	local writer = require(`./writer/init.lua`)

	addSection("uint", main.uint)
	addSection("int", main.int)
	addSection("float", main.float)

	addSection("base conversion", baseconversion)
	addSection("reader", reader)
	addSection("writer", writer)
end

table.insert(output, "return bitbuffer")

fs.writeFile("lune/output.luau", table.concat(output, "\n\n"):gsub("\n%s+\n", "\n\n"))
