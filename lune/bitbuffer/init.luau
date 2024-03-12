local uint = require("./uint.luau")
local int = require("./int.luau")
local float = require("./float.luau")
local string = require("./string.luau")
local other = require("./other/init.luau")
local baseconversion = require("./baseconversion/init.luau")

return function(luau, typescript)
	typescript:Push("declare interface bitbuffer {", 1)

	luau:LuauBlock("uint", uint, typescript)
		:Break()
		:LuauBlock("int", int, typescript)
		:Break()
		:LuauBlock("float", float, typescript)
		:Break()
		:LuauBlock("string", string, typescript)
		:Break()
		:LuauBlock("other", other, typescript)
		:Break()
		:LuauBlock("base conversion", baseconversion, typescript)

	-- stylua: ignore
	typescript:Push(
		"offset: {", 1,
			"(): Offset;",
			"(offset: number): Offset;",
			"(byte: number, bit: number): Offset;",
		-1, "}",
		"reader: (b: buffer) => Reader;",
		"writer: (b: buffer) => Writer;"
	)

	typescript:Push(-1, "}"):Break()
end
