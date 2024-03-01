-- https://dom.rojo.space/binary.html#cframe
local CFRAME_SPECIAL_CASES = [[local RAD_90, RAD_180 = math.rad(90), math.rad(180)

local CFRAME_SPECIAL_CASES = if CFrame then {
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
} else nil]]

local reader = require("./reader.luau")
local writer = require("./writer.luau")
local offset = require("./offset/init.luau")

return function(luau, typescript)
	-- stylua: ignore
	luau:Block("offset", offset, typescript)
		:Push("")
		:BlockStart("do -- reader & writer")
		:Push(CFRAME_SPECIAL_CASES)
		:Push("")
		:Block("writer", writer, typescript)
		:Push("")
		:Block("reader", reader, typescript)
		:BlockEnd()
end
