local reader = require("./reader.luau")
local writer = require("./writer.luau")

return function(addSection)
	local output = {}
	addSection("writer", writer, output)
	addSection("reader", reader, output)
	return output
end
