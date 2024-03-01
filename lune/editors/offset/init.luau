local fs = require("@lune/fs")

local function getFile(fileName: string)
	return (fs.readFile(`lune/editors/offset/{fileName}.luau`):gsub("\n$", ""))
end

return function(luau, typescript)
	luau:Push(getFile("source"))

	typescript
		:BlockStart("declare interface Offset {")
		:Push("byte: number;")
		:Push("bit: number;")
		:Push("")
		:BlockStart("SetOffset: {")
		:Push("(byte: number, bit: number): void;")
		:Push("(offset: number): void;")
		:BlockEnd("}")
		:BlockStart("IncrementOffset: {")
		:Push("(byte: number, bit: number): void;")
		:Push("(offset: number): void;")
		:BlockEnd("}")
		:Push("Align: () => void;")
		:BlockEnd("}")
		:Push("")
end
