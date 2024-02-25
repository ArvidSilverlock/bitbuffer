local Snippet = require("../Snippet/init.luau")

local uint = require("./uint.luau")
local int = require("./int.luau")
local float = require("./float.luau")
local string = require("./string.luau")
local other = require("./other/init.luau")
local baseconversion = require("./baseconversion/init.luau")

return function(addSection)
	local output = {}
	local tsOutput = Snippet.new()

	addSection("uint", uint, output, tsOutput)
	addSection("int", int, output, tsOutput)
	addSection("float", float, output, tsOutput)
	addSection("string", string, output, tsOutput)
	addSection("other", other, output, tsOutput)
	addSection("base conversion", baseconversion, output, tsOutput)

	tsOutput:Push("reader: (b: buffer) => Reader;")
	tsOutput:Push("writer: (b: buffer) => Writer;")

	tsOutput:Indent()
	tsOutput:Insert(1, "declare interface bitbuffer {")
	tsOutput:Push("}")

	return output, tostring(tsOutput)
end
