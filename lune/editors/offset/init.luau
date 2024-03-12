local fs = require("@lune/fs")

local function getFile(fileName: string)
	return (fs.readFile(`lune/editors/offset/{fileName}.luau`):gsub("\n$", ""))
end

return function(luau, typescript)
	luau:Push(getFile("source"))

	-- stylua: ignore
	typescript:Push(
		"declare interface Offset {", 1,
			"byte: number;",
			"bit: number;",
			"",
			"SetOffset: {", 1,
				"(byte: number, bit: number): void;",
				"(offset: number): void;",
			-1, "}",
			"IncrementOffset: {", 1,
				"(byte: number, bit: number): void;",
				"(offset: number): void;",
			-1, "}",
			"Align: () => void;",
		-1, "}",
		""
	)
end
