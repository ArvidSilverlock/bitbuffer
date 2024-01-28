local fs = require("@lune/fs")

local function insertFile(output, fileName: string)
	local str = fs.readFile(`lune/baseconversion/{fileName}.luau`):gsub("\n$", "")
	table.insert(output, str)
end

local function append(output)
	insertFile(output, "constants")
	insertFile(output, "binary")
	insertFile(output, "hexadecimal")
	insertFile(output, "base64")
end

return append
