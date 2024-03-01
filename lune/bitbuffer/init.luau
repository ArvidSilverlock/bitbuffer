local uint = require("./uint.luau")
local int = require("./int.luau")
local float = require("./float.luau")
local string = require("./string.luau")
local other = require("./other/init.luau")
local baseconversion = require("./baseconversion/init.luau")

return function(luau, typescript)
	typescript:BlockStart("declare interface bitbuffer {")

	luau:Block("uint", uint, typescript)
		:Push("")
		:Block("int", int, typescript)
		:Push("")
		:Block("float", float, typescript)
		:Push("")
		:Block("string", string, typescript)
		:Push("")
		:Block("other", other, typescript)
		:Push("")
		:Block("base conversion", baseconversion, typescript)

	typescript
		:BlockStart("offset: {")
		:Push("(): Offset;")
		:Push("(offset: number): Offset;")
		:Push("(byte: number, bit: number): Offset;")
		:BlockEnd("}")
		:Push("reader: (b: buffer) => Reader;")
		:Push("writer: (b: buffer) => Writer;")

	typescript:BlockEnd("}"):Push("")
end
