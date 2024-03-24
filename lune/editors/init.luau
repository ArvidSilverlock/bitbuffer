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
local offset = require("./offset.luau")

return function(luau, typescript)
	-- stylua: ignore
	luau:LuauBlock("offset", offset, typescript)
		:Break()
		:Push(
			"do -- reader & writer", 1,
			CFRAME_SPECIAL_CASES
		)
		:Break()
		:LuauBlock("writer", writer, typescript)
		:Break()
		:LuauBlock("reader", reader, typescript)
		:Push(-1, "end")
end
