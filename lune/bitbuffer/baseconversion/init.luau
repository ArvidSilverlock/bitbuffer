local fs = require("@lune/fs")

local function get(fileName: string)
	return (fs.readFile(`lune/bitbuffer/baseconversion/{fileName}.luau`):gsub("\n$", ""))
end

return function(luau, typescript)
	-- stylua: ignore start
	luau:Push(get("constants"))
		:Push("")
		:Block("binary", get("binary"))
		:Push("")
		:Block("hexadecimal", get("hexadecimal"))
		:Push("")
		:Block("base64", get("base64"))
		:Push("")

	typescript:Push("tobinary: (b: buffer, separator?: string) => string;")
		:Push("frombinary: (str: string, separator?: string) => buffer;")
		:Push("")
		:Push("tohexadecimal: (b: buffer, separator?: string) => string;")
		:Push("fromhexadecimal: (str: string, separator?: string) => buffer;")
		:Push("")
		:Push("tobase64: (b: buffer) => string;")
		:Push("frombase64: (str: string) => buffer;")
		:Push("")

	-- stylua: ignore end
end
