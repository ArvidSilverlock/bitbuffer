local function Type(type: string)
	return function(width: number)
		return { type = type, width = width }
	end
end
local UInt = Type("UInt")
local Int = Type("Int")
local Float = Type("Float")
local Alpha = Type("Alpha")

return {
	Vector3 = {
		Values = { "X", "Y", "Z" },
		Types = { X = Float(32), Y = Float(32), Z = Float(32) },
	},
	Vector3int16 = {
		Values = { "X", "Y", "Z" },
		Types = { X = Int(16), Y = Int(16), Z = Int(16) },
	},

	Vector2 = {
		Values = { "X", "Y" },
		Types = { X = Float(32), Y = Float(32) },
	},
	Vector2int16 = {
		Values = { "X", "Y" },
		Types = { X = Int(16), Y = Int(16) },
	},

	BrickColor = {
		Values = { "Number" },
		Types = { Number = UInt(11) },
	},
	Color3 = {
		Values = { "R", "G", "B" },
		Types = { R = Alpha(8), G = Alpha(8), B = Alpha(8) },
	},

	UDim = {
		Values = { "Scale", "Offset" },
		Types = { Scale = Float(32), Offset = Int(32) },
	},
	UDim2 = {
		Values = { "X", "Y" },
		Types = { X = "UDim", Y = "UDim" },
	},

	NumberRange = {
		Values = { "Min", "Max" },
		Types = { Min = Float(32), Max = Float(32) },
	},

	NumberSequenceKeypoint = {
		Values = { "Time", "Value", "Envelope" },
		Types = { Time = Float(32), Value = Float(32), Envelope = Float(32) },
	},
	ColorSequenceKeypoint = {
		Values = { "Time", "Value" },
		Types = { Time = Float(32), Value = "Color3" },
	},
}
