local fs = require("@lune/fs")

local function get(fileName: string)
	return (fs.readFile(`lune/baseconversion/{fileName}.luau`):gsub("\n$", ""))
end

local function create(addSection)
	local output = {}
	table.insert(output, get("constants"))
	addSection("binary", get("binary"), output)
	addSection("hexadecimal", get("hexadecimal"), output)
	addSection("base64", get("base64"), output)
	return output
end

return create
