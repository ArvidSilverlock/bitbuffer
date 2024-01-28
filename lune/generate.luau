local process = require("@lune/process")
local fs = require("@lune/fs")

local output = {}

-- stylua: ignore
table.insert(output, [[--!native
--!optimize 2
--!strict
-- stylua: ignore start

local bitbuffer = {}]])

if process.args[1] then
	for _, argument in process.args do
		local callback = require(`./{argument}/init.lua`)
		callback(output)
	end
else
	local main = require(`./main/init.lua`)
	local baseconversion = require(`./baseconversion/init.lua`)
	local reader = require(`./reader/init.lua`)
	local writer = require(`./writer/init.lua`)

	main(output)
	baseconversion(output)
	reader(output)
	writer(output)
end

table.insert(output, "return bitbuffer")

fs.writeFile("lune/output.luau", table.concat(output, "\n\n"):gsub("\n\t+\n", "\n\n"))
