local fs = require("@lune/fs")

local CONSTRUCTOR = [[function bitbuffer.offset(byte: number?, bit: number?)
	local self = {}
	self.__index = self

	if byte and bit then
		self.byte, self.bit = byte, bit
	elseif byte then
		self.byte, self.bit = byte // 8, byte % 8
	else
		self.byte, self.bit = 0, 0
	end

	return setmetatable(self, Offset)
end]]

local function getFile(fileName: string)
	return (fs.readFile(`lune/editors/{fileName}.luau`):gsub("\n$", ""))
end

return function(luau, typescript)
	luau:Push((getFile("offsetHandler"):gsub("CLASS", "Offset"))):Break():Push(CONSTRUCTOR)

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
