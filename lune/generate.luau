local process = require("@lune/process")
local fs = require("@lune/fs")

local output = {}

-- stylua: ignore
table.insert(output, [[--!native
--!optimize 2
--!strict

-- stylua: ignore start
---@diagnostic disable: undefined-type

local bitbuffer = {}]])

local function addSection(name, create, outputTable)
	local section = create(addSection)
	local str = table.concat(section, "\n\n")
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
