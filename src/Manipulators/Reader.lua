local Constants = require(script.Parent.Constants)

local CFRAME_SPECIAL_CASES = Constants.CFrameSpecialCases

local ENUMS = Constants.Enums
local ENUM_WIDTHS = Constants.EnumWidths
local ENUM_CODE_WIDTH = Constants.EnumCodeWidth

local function UInt(width: number)
	return function(self): number
		return self:UInt(width)
	end
end

local function Int(width: number)
	local min = -2 ^ (width - 1)
	return function(self): number
		return self:UInt(width) + min
	end
end

local function Float(exponentWidth: number, fractionWidth: number)
	local exponentMax = 2 ^ exponentWidth - 1
	local uintToFraction = 2 ^ fractionWidth

	return function(self): number
		local sign, exponent, fraction = self:UInt(1) * -2 + 1, self:UInt(exponentWidth), self:UInt(fractionWidth)

		if exponent == exponentMax then
			return if fraction == 0 then math.huge * sign else 0 / 0
		else
			return math.ldexp(fraction / uintToFraction, exponent) * sign
		end
	end
end

local Reader = {}
Reader.__index = Reader

function Reader:Variadic<T>(readCallback: (any) -> T, count: number): ...T
	local output = table.create(count)
	for i = 1, count do
		output[i] = readCallback(self)
	end
	return table.unpack(output, 1, count)
end

function Reader:UInt(width: number): number
	local value = self.read(self._buffer, self._offset, width)
	self._offset += width
	return value
end

function Reader:Int(width: number): number
	return self:UInt(width) - 2 ^ (width - 1)
end

function Reader:Boolean(): boolean
	return self:UInt(1) == 1
end

function Reader:String(lengthWidth: number?): string
	local stringLength = self:UInt(lengthWidth or 16)

	local stringBuffer = buffer.create(stringLength)
	for stringOffset = 0, stringLength - 1 do
		buffer.writeu8(stringBuffer, stringOffset, self:UInt8())
	end
	return buffer.tostring(stringBuffer)
end

function Reader:NullTerminatedString(): string
	local output = {}
	while true do
		local value = self:UInt8()
		if value == 0 then
			break
		end

		table.insert(output, string.char(value))
	end
	return table.concat(output)
end

function Reader:Vector3(): Vector3
	return Vector3.new(self:Float32(), self:Float32(), self:Float32())
end

function Reader:Vector3int16(): Vector3int16
	return Vector3int16.new(self:Int16(), self:Int16(), self:Int16())
end

function Reader:Vector2(): Vector2
	return Vector2.new(self:Float32(), self:Float32())
end

function Reader:Vector2int16(): Vector2int16
	return Vector2int16.new(self:Int16(), self:Int16())
end

function Reader:CFrame(): CFrame
	local specialCase = self:UInt(5)
	local position = self:Vector3()

	if specialCase == 0 then
		return CFrame.fromMatrix(position, self:Vector3(), self:Vector3(), self:Vector3())
	else
		local specialCase = CFRAME_SPECIAL_CASES[specialCase]
		return CFrame.fromMatrix(position, specialCase.XVector, specialCase.YVector, specialCase.ZVector)
	end
end

function Reader:BrickColor(): BrickColor
	return BrickColor.new(self:UInt(11) + 1)
end

function Reader:Color3(value: Color3)
	return Color3.fromRGB(self:UInt8(), self:UInt8(), self:UInt8())
end

function Reader:UDim(): UDim
	return UDim.new(self:Float32(), self:Float32())
end

function Reader:UDim2(): UDim2
	return UDim2.new(self:UDim(), self:UDim())
end

function Reader:NumberRange(): NumberRange
	return NumberRange.new(self:Float32(), self:Float32())
end

function Reader:Enum(enumType: Enum?): EnumItem
	if not enumType then
		enumType = ENUMS[self:UInt(ENUM_CODE_WIDTH) + 1]
	end

	local enumCode = self:UInt(ENUM_WIDTHS[enumType]) + 1
	return enumType[enumCode]
end

function Reader:ColorSequence(): ColorSequence
	local length = self:UInt(5) -- max length of 20, tested
	local keypoints = table.create(length)

	for _ = 1, length do
		local keypoint = ColorSequenceKeypoint.new(self:Float32(), self:Color3())
		table.insert(keypoints, keypoint)
	end

	return ColorSequence.new(keypoints)
end

function Reader:NumberSequence(readEnvelope: boolean?): NumberSequence
	local length = self:UInt(5) -- max length of 20, tested
	local keypoints = table.create(length)

	for _ = 1, length do
		local time, value = self:Float32(), self:Float32()
		local envelope = if readEnvelope then self:Float32() else nil

		local keypoint = ColorSequenceKeypoint.new(time, value, envelope)
		table.insert(keypoints, keypoint)
	end

	return NumberSequence.new(keypoints)
end

Reader.UInt8 = UInt(8)
Reader.UInt16 = UInt(16)
Reader.UInt24 = UInt(24)
Reader.UInt32 = UInt(32)

Reader.Int8 = Int(8)
Reader.Int16 = Int(16)
Reader.Int24 = Int(24)
Reader.Int32 = Int(32)

Reader.Float16 = Float(5, 10)
Reader.Float32 = Float(8, 23)
Reader.Float64 = Float(11, 52)

return Reader
