local fs = require("@lune/fs")

local function get(fileName: string)
	return (fs.readFile(`lune/bitbuffer/baseconversion/{fileName}.luau`):gsub("\n$", ""))
end

return function(luau, typescript)
	-- stylua: ignore start
	luau:Push(get("constants"))
		:Break()
		:LuauBlock("binary", get("binary"))
		:Break()
		:LuauBlock("hexadecimal", get("hexadecimal"))
		:Break()
		:LuauBlock("base64", get("base64"))
		:Break()

	typescript:Push(
		"tobinary: (b: buffer, separator?: string) => string;",
		"frombinary: (str: string, separator?: string) => buffer;",
		"",
		"tohexadecimal: (b: buffer, separator?: string) => string;",
		"fromhexadecimal: (str: string, separator?: string) => buffer;",
		"",
		"tobase64: (b: buffer) => string;",
		"frombase64: (str: string) => buffer;",
		""
	)
	-- stylua: ignore end
end
