local Constants = require(script.Parent.Constants)

local CFRAME_SPECIAL_CASES = Constants.CFrameSpecialCases

local ENUM_CODES = Constants.EnumCodes
local ENUM_WIDTHS = Constants.EnumWidths
local ENUM_CODE_WIDTH = Constants.EnumCodeWidth

local function getCFrameSpecialCase(cframe)
	for index, case in CFRAME_SPECIAL_CASES do
		if cframe.Rotation == case then
			return index
		end
	end
end

local function UInt(width: number)
	return function(self, value: number)
		self:UInt(value, width)
	end
end

local function Int(width: number)
	local min = -2 ^ (width - 1)
	return function(self, value: number)
		self:UInt(value - min, width)
	end
end

local function Float(exponentWidth: number, fractionWidth: number)
	local combinedWidth = exponentWidth + fractionWidth
	local totalWidth = combinedWidth + 1

	local exponentMax = 2 ^ exponentWidth - 1
	local fractionMax = 2 ^ fractionWidth - 1
	local fractionToUInt = 2 ^ fractionWidth

	return function(self, value: number)
		if value == math.huge then
			self:UInt(if value < 0 then 1 else 0, 1)
			self:UInt(exponentMax, exponentWidth)
			self:UInt(0, fractionWidth)
		elseif value ~= value then
			self:UInt(0, 1)
			self:UInt(exponentMax, exponentWidth)
			self:UInt(fractionMax, fractionWidth)
		elseif value == 0 then
			self:UInt(0, totalWidth)
		else
			local fraction, exponent = math.frexp(value)
			self:UInt(if value < 0 then 1 else 0, 1)
			self:UInt(exponent, exponentWidth)
			self:UInt(math.ceil(math.abs(fraction) * fractionToUInt), fractionWidth)
		end
	end
end

local Writer = {}
Writer.__index = Writer

function Writer:Variadic<T>(writeCallback: (any, value: T) -> (), ...: T)
	for i = 1, select("#", ...) do
		writeCallback(self, select(i, ...))
	end
end

function Writer:UInt(value: number, width: number)
	self.write(self._buffer, self._offset, value, width)
	self._offset += width
end

Writer.UInt8 = UInt(8)
Writer.UInt16 = UInt(16)
Writer.UInt24 = UInt(24)
Writer.UInt32 = UInt(32)

function Writer:Int(value: number, width: number)
	self:UInt(if value < 0 then value + 2 ^ (width - 1) else value, width)
end

Writer.Int8 = Int(8)
Writer.Int16 = Int(16)
Writer.Int24 = Int(24)
Writer.Int32 = Int(32)

Writer.Float16 = Float(5, 10)
Writer.Float32 = Float(8, 23)
Writer.Float64 = Float(11, 52)

function Writer:Boolean(value: boolean)
	self:UInt(if value then 1 else 0, 1)
end

function Writer:String(value: string, lengthWidth: number?)
	local stringLength = #value
	self:UInt(stringLength, lengthWidth or 16)

	local stringBuffer = buffer.fromstring(value)
	for stringOffset = 0, stringLength - 1 do
		self:UInt8(buffer.readu8(stringBuffer, stringOffset))
	end
end

function Writer:NullTerminatedString(value: string)
	local stringBuffer = buffer.fromstring(value)
	for stringOffset = 0, #value - 1 do
		self:UInt8(buffer.readu8(stringBuffer, stringOffset))
	end
	self:UInt(0, 8)
end

function Writer:Vector3(value: Vector3)
	self:Float32(value.X)
	self:Float32(value.Y)
	self:Float32(value.Z)
end

function Writer:Vector3int16(value: Vector3int16)
	self:Int16(value.X)
	self:Int16(value.Y)
	self:Int16(value.Z)
end

function Writer:Vector2(value: Vector2)
	self:Float32(value.X)
	self:Float32(value.Y)
end

function Writer:Vector2int16(value: Vector2int16)
	self:Int16(value.X)
	self:Int16(value.Y)
end

function Writer:CFrame(value: CFrame)
	local specialCase = getCFrameSpecialCase(value)
	self:UInt(specialCase, 5)

	self:Vector3(value.Position)
	if specialCase == 0 then
		self:Vector3(value.XVector)
		self:Vector3(value.YVector)
		self:Vector3(value.ZVector)
	end
end

function Writer:BrickColor(value: BrickColor)
	self:UInt(value.Number - 1, 11)
end

function Writer:Color3(value: Color3)
	self:UInt8(math.floor(value.R * 255))
	self:UInt8(math.floor(value.G * 255))
	self:UInt8(math.floor(value.B * 255))
end

function Writer:UDim(value: UDim)
	self:Float32(value.Scale)
	self:Int32(value.Offset)
end

function Writer:UDim2(value: UDim2)
	self:UDim(value.X)
	self:UDim(value.Y)
end

function Writer:NumberRange(value: NumberRange)
	self:Float32(value.Min)
	self:Float32(value.Max)
end

function Writer:Enum(value: EnumItem, enumType: Enum?)
	if not enumType then
		self:UInt(ENUM_CODES[value.EnumType], ENUM_CODE_WIDTH)
	end

	self:UInt(value.Value, ENUM_WIDTHS[value.EnumType])
end

function Writer:ColorSequence(value: ColorSequence)
	self:UInt(#value.Keypoints, 5) -- max length of 20, tested
	for _, keypoint in value.Keypoints do
		self:Float32(keypoint.Time)
		self:Color3(keypoint.Value)
	end
end

function Writer:NumberSequence(value: NumberSequence, writeEnvelope: boolean?)
	self:UInt(#value.Keypoints, 5) -- max length of 20, tested
	for _, keypoint in value.Keypoints do
		self:Float32(keypoint.Time)
		self:Float32(keypoint.Value)
		if writeEnvelope ~= false then
			self:Float32(keypoint.Envelope)
		end
	end
end

return Writer
