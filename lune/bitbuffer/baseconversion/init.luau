local fs = require("@lune/fs")

local function get(fileName: string)
	return (fs.readFile(`lune/bitbuffer/baseconversion/{fileName}.luau`):gsub("\n$", ""))
end

local function create(addSection, tsOutput)
	local output = {}
	table.insert(output, get("constants"))
	addSection("binary", get("binary"), output)
	addSection("hexadecimal", get("hexadecimal"), output)
	addSection("base64", get("base64"), output)

	tsOutput:Push("tobinary: (b: buffer, separator?: string) => string;")
	tsOutput:Push("frombinary: (str: string, separator?: string) => buffer;")
	tsOutput:Push("")

	tsOutput:Push("tohexadecimal: (b: buffer, separator?: string) => string;")
	tsOutput:Push("fromhexadecimal: (str: string, separator?: string) => buffer;")
	tsOutput:Push("")

	tsOutput:Push("tobase64: (b: buffer) => string;")
	tsOutput:Push("frombase64: (str: string) => buffer;")
	tsOutput:Push("")

	return output
end

return create
