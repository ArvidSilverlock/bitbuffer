-- https://dom.rojo.space/binary.html#cframe
local CFRAME_SPECIAL_CASES = [[local RAD_90, RAD_180 = math.rad(90), math.rad(180)

local CFRAME_SPECIAL_CASES = {
	CFrame.Angles(0, 0, 0),
	CFrame.Angles(RAD_90, 0, 0),
	CFrame.Angles(0, RAD_180, RAD_180),
	CFrame.Angles(-RAD_90, 0, 0),
	CFrame.Angles(0, RAD_180, RAD_90),
	CFrame.Angles(0, RAD_90, RAD_90),
	CFrame.Angles(0, 0, RAD_90),
	CFrame.Angles(0, -RAD_90, RAD_90),
	CFrame.Angles(-RAD_90, -RAD_90, 0),
	CFrame.Angles(0, -RAD_90, 0),
	CFrame.Angles(RAD_90, -RAD_90, 0),
	CFrame.Angles(0, RAD_90, RAD_180),
	CFrame.Angles(0, -RAD_90, RAD_180),
	CFrame.Angles(0, RAD_180, 0),
	CFrame.Angles(-RAD_90, math.rad(-180), 0),
	CFrame.Angles(0, 0, RAD_180),
	CFrame.Angles(RAD_90, RAD_180, 0),
	CFrame.Angles(0, 0, -RAD_90),
	CFrame.Angles(0, -RAD_90, -RAD_90),
	CFrame.Angles(0, math.rad(-180), -RAD_90),
	CFrame.Angles(0, RAD_90, -RAD_90),
	CFrame.Angles(RAD_90, RAD_90, 0),
	CFrame.Angles(0, RAD_90, 0),
	CFrame.Angles(-RAD_90, RAD_90, 0),
}]]

local reader = require("./reader.luau")
local writer = require("./writer.luau")

return function(addSection)
	local output = {}

	table.insert(output, CFRAME_SPECIAL_CASES)
	addSection("writer", writer, output)
	addSection("reader", reader, output)

	return output
end
