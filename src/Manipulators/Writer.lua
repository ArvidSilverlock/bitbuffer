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

--- @class Writer
local Writer = {}
Writer.__index = Writer

--[=[
	@method Align
	@within Writer

	Aligns the current offset to the *next* byte, which speeds up `write` calls slightly
]=]
function Writer:Align()
	self._offset = bit32.lshift(bit32.rshift(self._offset + 7, 3), 3) -- math.ceil(self._offset / 8) * 8
end

--[=[
	@method Skip
	@within Writer

	Skips the specified number of bits, without altering them

	@param amount number
]=]
function Writer:Skip(amount: number)
	self._offset += amount
end

--[=[
	@method Variadic
	@within Writer

	Writes a varying amount of values of the same type

	@param writeCallback <T>(self, value: T) -> ()
	@param ... T
]=]
function Writer:Variadic<T>(writeCallback: (any, value: T) -> (), ...: T)
	for i = 1, select("#", ...) do
		writeCallback(self, select(i, ...))
	end
end

--[=[
	@method UInt
	@within Writer

	Writes an unsigned integer of any width from 1-53

	@param value number -- The uint to write
	@param width number -- The bit width of the `value`
]=]
function Writer:UInt(value: number, width: number)
	self.write(self._buffer, self._offset, value, width)
	self._offset += width
end

--[=[
	@method Int
	@within Writer

	Writes a signed integer of any width from 1-53, note that one of these bits is used as the sign

	@param value number
	@param width number
]=]
function Writer:Int(value: number, width: number)
	self:UInt(if value < 0 then value + 2 ^ (width - 1) else value, width)
end

--[=[
	@method Boolean
	@within Writer

	Writes a boolean

	@param value boolean
]=]
function Writer:Boolean(value: boolean)
	self:UInt(if value then 1 else 0, 1)
end

--[=[
	@method String
	@within Writer

	Writes a string with its length encoded using a specified number of bits

	@param value string
	@param lengthWidth number? -- Amount of bits to encode the string length with, defaults to 16
]=]
function Writer:String(value: string, lengthWidth: number?)
	local stringLength = #value
	self:UInt(stringLength, lengthWidth or 16)

	local stringBuffer = buffer.fromstring(value)
	for stringOffset = 0, stringLength - 1 do
		self:UInt8(buffer.readu8(stringBuffer, stringOffset))
	end
end

--[=[
	@method NullTerminatedString
	@within Writer

	Writes a string until it finds a character with the value of 0, if one is not found, it will write one on the end

	@param value string
]=]
function Writer:NullTerminatedString(value: string)
	local stringBuffer = buffer.fromstring(value)
	for stringOffset = 0, #value - 1 do
		local character = buffer.readu8(stringBuffer, stringOffset)
		if character == 0 then
			break
		end

		self:UInt8(character)
	end
	self:UInt(0, 8)
end

--[=[
	@method Vector3
	@within Writer

	Writes a `Vector3` using 3 `Float32`s

	@param value Vector3
]=]
function Writer:Vector3(value: Vector3)
	self:Float32(value.X)
	self:Float32(value.Y)
	self:Float32(value.Z)
end

--[=[
	@method Vector3int16
	@within Writer

	Writes a `Vector3int16` using 3 `Int16`s

	@param value Vector3int16
]=]
function Writer:Vector3int16(value: Vector3int16)
	self:Int16(value.X)
	self:Int16(value.Y)
	self:Int16(value.Z)
end

--[=[
	@method Vector2
	@within Writer

	Writes a `Vector2` using 2 `Int32`s

	@param value Vector2
]=]
function Writer:Vector2(value: Vector2)
	self:Float32(value.X)
	self:Float32(value.Y)
end

--[=[
	@method Vector2int16
	@within Writer

	Writes a `Vector2int16` using 2 `Int16`s

	@param value Vector2int16
]=]
function Writer:Vector2int16(value: Vector2int16)
	self:Int16(value.X)
	self:Int16(value.Y)
end

--[=[
	@method CFrame
	@within Writer

	Writes a `CFrame` using a 5 bit unsigned integer to specify an axis aligned case along with its `Vector3` position, if the `CFrame` isn't axis aligned, it will encode the `XVector`, `YVector` and, `ZVector` too

	@param value CFrame
]=]
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

--[=[
	@method BrickColor
	@within Writer

	Writes a `BrickColor` using an 11 bit unsigned integer

	@param value BrickColor
]=]
function Writer:BrickColor(value: BrickColor)
	self:UInt(value.Number - 1, 11)
end

--[=[
	@method Color3
	@within Writer

	Writes 3 bytes, one for each RGB component

	@param value Color3
]=]
function Writer:Color3(value: Color3)
	self:UInt8(math.floor(value.R * 255))
	self:UInt8(math.floor(value.G * 255))
	self:UInt8(math.floor(value.B * 255))
end

--[=[
	@method UDim
	@within Writer

	Writes a `UDim` using a `Float32` and `Int32`

	@param value UDim
]=]
function Writer:UDim(value: UDim)
	self:Float32(value.Scale)
	self:Int32(value.Offset)
end

--[=[
	@method UDim2
	@within Writer

	Writes a `UDim2` using two `UDim`s

	@param value UDim2
]=]
function Writer:UDim2(value: UDim2)
	self:UDim(value.X)
	self:UDim(value.Y)
end

--[=[
	@method NumberRange
	@within Writer

	Writes a `NumberRange` using two `Float32`s

	@param value NumberRange
]=]
function Writer:NumberRange(value: NumberRange)
	self:Float32(value.Min)
	self:Float32(value.Max)
end

--[=[
	@method Enum
	@within Writer

	If no `enumType` is specified, it will encode the `EnumItem.Type`, then encode the `EnumItem` using unsigned integers whose widths depend on the amount of possible values.
	
	This is good for short term usage, such as sending over the network, but, bad for long term storage (i.e., storing in a datastore), this is because a roblox update might add aditional `Enum`s or `EnumItems`, altering the required value widths

	@param value EnumItem
	@param enumType Enum? -- If specified, it will skip the encoding of the `EnumType`
]=]
function Writer:Enum(value: EnumItem, enumType: Enum?)
	if not enumType then
		self:UInt(ENUM_CODES[value.EnumType], ENUM_CODE_WIDTH)
	end

	self:UInt(value.Value, ENUM_WIDTHS[value.EnumType])
end

--[=[
	@method ColorSequence
	@within Writer

	Encodes a `ColorSequence` using an unsigned 5 bit integer for the length, then a `Float32` for the `Time` and a `Color3` for the `Value` of each keypoint

	@param value ColorSequence
]=]
function Writer:ColorSequence(value: ColorSequence)
	self:UInt(#value.Keypoints, 5) -- max length of 20, tested
	for _, keypoint in value.Keypoints do
		self:Float32(keypoint.Time)
		self:Color3(keypoint.Value)
	end
end

--[=[
	@method NumberSequence
	@within Writer

	Encodes a `NumberSequence` using an unsigned 5 bit integer for the length, then a `Float32` for the `Time`, `Value` and `Envelope` of each keypoint

	@param value NumberSequence
	@param writeEnvelope boolean? -- Whether or not to include the `Envelope` in the output, defaults to `false`
]=]
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

--[=[
	@method UInt8
	@within Writer

	Writes an 8 bit unsigned integer

	@param value number
]=]
Writer.UInt8 = UInt(8)

--[=[
	@method UInt16
	@within Writer

	Writes a 16 bit unsigned integer

	@param value number
]=]
Writer.UInt16 = UInt(16)

--[=[
	@method UInt24
	@within Writer

	Writes a 24 bit unsigned integer

	@param value number
]=]
Writer.UInt24 = UInt(24)

--[=[
	@method UInt32
	@within Writer

	Writes a 32 bit unsigned integer

	@param value number
]=]
Writer.UInt32 = UInt(32)

--[=[
	@method Int8
	@within Writer

	Writes an 8 bit signed integer

	@param value number
]=]
Writer.Int8 = Int(8)

--[=[
	@method Int16
	@within Writer

	Writes a 16 bit signed integer

	@param value number
]=]
Writer.Int16 = Int(16)

--[=[
	@method Int24
	@within Writer

	Writes a 24 bit signed integer

	@param value number
]=]
Writer.Int24 = Int(24)

--[=[
	@method Int32
	@within Writer

	Writes a 32 bit signed integer

	@param value number
]=]
Writer.Int32 = Int(32)

--[=[
	@method Float16
	@within Writer

	Writes a half-precision floating point number

	@param value number
]=]
Writer.Float16 = Float(5, 10)

--[=[
	@method Float32
	@within Writer

	Writes a single-precision floating point number

	@param value number
]=]
Writer.Float32 = Float(8, 23)

--[=[
	@method Float64
	@within Writer

	Writes a double-precision floating point number

	@param value number
]=]
Writer.Float64 = Float(11, 52)

return Writer
