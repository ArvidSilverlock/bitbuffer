local Constants = require(script.Parent.Constants)

local CFRAME_SPECIAL_CASES = Constants.CFrameSpecialCases

local ENUMS = Constants.Enums
local ENUM_WIDTHS = Constants.EnumWidths
local ENUM_LOOKUP = Constants.EnumLookup
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

--- @class Reader
local Reader = {}
Reader.__index = Reader

--[=[
	@method Align
	@within Reader

	Aligns the current offset to the *next* byte, which speeds up `write` calls slightly
]=]
function Reader:Align()
	self._offset = bit32.lshift(bit32.rshift(self._offset + 7, 3), 3) -- math.ceil(self._offset / 8) * 8
end

--[=[
	@method Skip
	@within Reader

	Skips the specified number of bits, without altering them

	@param amount number
]=]
function Reader:Skip(amount: number)
	self._offset += amount
end

--[=[
	@method Variadic
	@within Reader

	Reads a specified amount of values of the same type

	@param readCallback <T>(self) -> T
	@param count number -- The amount of values to read

	@return ... T
]=]
function Reader:Variadic<T>(readCallback: (any) -> T, count: number): ...T
	local output = table.create(count)
	for i = 1, count do
		output[i] = readCallback(self)
	end
	return table.unpack(output, 1, count)
end

--[=[
	@method UInt
	@within Reader

	Reads an unsigned integer of any width from 1-52

	@param width number -- The bit width to read

	@return number
]=]
function Reader:UInt(width: number): number
	local value = self.read(self._buffer, self._offset, width)
	self._offset += width
	return value
end

--[=[
	@method Int
	@within Reader

	Reads a signed integer of any width from 1-52, note that one of these bits is used as the sign

	@param width number

	@return number
]=]
function Reader:Int(width: number): number
	return self:UInt(width) - 2 ^ (width - 1)
end

--[=[
	@method Boolean
	@within Reader

	Reads a boolean

	@return boolean
]=]
function Reader:Boolean(): boolean
	return self:UInt(1) == 1
end

--[=[
	@method String
	@within Reader

	Reads a string that has its length encoded using a specified number of bits

	@param lengthWidth number? -- Amount of bits used to encode the string length with, defaults to 16
	@return string
]=]
function Reader:String(lengthWidth: number?): string
	local stringLength = self:UInt(lengthWidth or 16)

	local stringBuffer = buffer.create(stringLength)
	for stringOffset = 0, stringLength - 1 do
		buffer.writeu8(stringBuffer, stringOffset, self:UInt8())
	end
	return buffer.tostring(stringBuffer)
end

--[=[
	@method NullTerminatedString
	@within Reader

	Reads characters of a string until it encounters a byte with a value of 0

	@return string
]=]
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

--[=[
	@method Vector3
	@within Reader

	Reads a `Vector3` using 3 `Float32`s

	@return Vector3
]=]
function Reader:Vector3(): Vector3
	return Vector3.new(self:Float32(), self:Float32(), self:Float32())
end

--[=[
	@method Vector3int16
	@within Reader

	Reads a `Vector3int16` using 3 `Int16`s

	@return Vector3int16
]=]
function Reader:Vector3int16(): Vector3int16
	return Vector3int16.new(self:Int16(), self:Int16(), self:Int16())
end

--[=[
	@method Vector2
	@within Reader

	Reads a `Vector2` using 2 `Float32`s

	@return Vector2
]=]
function Reader:Vector2(): Vector2
	return Vector2.new(self:Float32(), self:Float32())
end

--[=[
	@method Vector2int16
	@within Reader

	Reads a `Vector2int16` using 2 `Int16`s

	@return Vector2int16
]=]
function Reader:Vector2int16(): Vector2int16
	return Vector2int16.new(self:Int16(), self:Int16())
end

--[=[
	@method CFrame
	@within Reader

	Reads a `CFrame` using a 5 bit unsigned integer to specify an axis aligned case along with its `Vector3` position, if the `CFrame` isn't axis aligned, it will read an `XVector`, `YVector` and, `ZVector` too

	@return CFrame
]=]
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

--[=[
	@method BrickColor
	@within Reader

	Reads a `BrickColor` using an 11 bit unsigned integer

	@return BrickColor
]=]
function Reader:BrickColor(): BrickColor
	return BrickColor.new(self:UInt(11) + 1)
end

--[=[
	@method Color3
	@within Reader

	Reads 3 bytes, one for each RGB component

	@return Color3
]=]
function Reader:Color3()
	return Color3.fromRGB(self:UInt8(), self:UInt8(), self:UInt8())
end

--[=[
	@method UDim
	@within Reader

	Reads a `UDim` using a `Float32` and `Int32`

	@return UDim
]=]
function Reader:UDim(): UDim
	return UDim.new(self:Float32(), self:Int32())
end

--[=[
	@method UDim2
	@within Reader

	Reads a `UDim2` using two `UDim`s

	@return UDim2
]=]
function Reader:UDim2(): UDim2
	return UDim2.new(self:UDim(), self:UDim())
end

--[=[
	@method NumberRange
	@within Reader

	Reads a `NumberRange` using two `Float32`s

	@return NumberRange
]=]
function Reader:NumberRange(): NumberRange
	return NumberRange.new(self:Float32(), self:Float32())
end

--[=[
	@method Enum
	@within Reader

	If no `enumType` is specified, it will read the `EnumItem.Type`, then read the `EnumItem` using unsigned integers whose widths depend on the amount of possible values.
	
	@param enumType Enum? -- The `EnumItem.Type` that the read value should have

	@return EnumItem
]=]
function Reader:Enum(enumType: Enum?): EnumItem
	if not enumType then
		enumType = ENUMS[self:UInt(ENUM_CODE_WIDTH) + 1]
	end

	local enumCode = self:UInt(ENUM_WIDTHS[enumType]) + 1
	return ENUM_LOOKUP[enumType][enumCode]
end

--[=[
	@method ColorSequence
	@within Reader

	Reads a `ColorSequence` using an unsigned 5 bit integer for the length, then a `Float32` for the `Time` and a `Color3` for the `Value` of each keypoint

	@return ColorSequence
]=]
function Reader:ColorSequence(): ColorSequence
	local length = self:UInt(5) -- max length of 20, tested
	local keypoints = table.create(length)

	for _ = 1, length do
		local keypoint = ColorSequenceKeypoint.new(self:Float32(), self:Color3())
		table.insert(keypoints, keypoint)
	end

	return ColorSequence.new(keypoints)
end

--[=[
	@method NumberSequence
	@within Reader

	Reads a `NumberSequence` using an unsigned 5 bit integer for the length, then a `Float32` for the `Time`, `Value` and `Envelope` of each keypoint

	@param readEnvelope boolean? -- Whether or not the value of the `Envelope` is stored, and thus should be read out, defaults to `false`

	@return NumberSequence
]=]
function Reader:NumberSequence(readEnvelope: boolean?): NumberSequence
	local length = self:UInt(5) -- max length of 20, tested
	local keypoints = table.create(length)

	for _ = 1, length do
		local time, value = self:Float32(), self:Float32()
		local envelope = if readEnvelope then self:Float32() else nil

		local keypoint = NumberSequenceKeypoint.new(time, value, envelope)
		table.insert(keypoints, keypoint)
	end

	return NumberSequence.new(keypoints)
end

--[=[
	@method UInt8
	@within Reader

	Reads an 8 bit unsigned integer

	@return number
]=]
Reader.UInt8 = UInt(8)

--[=[
	@method UInt16
	@within Reader

	Reads an 16 bit unsigned integer

	@return number
]=]
Reader.UInt16 = UInt(16)

--[=[
	@method UInt24
	@within Reader

	Reads an 24 bit unsigned integer

	@return number
]=]
Reader.UInt24 = UInt(24)

--[=[
	@method UInt32
	@within Reader

	Reads an 32 bit unsigned integer

	@return number
]=]
Reader.UInt32 = UInt(32)

--[=[
	@method UInt8
	@within Reader

	Reads an 8 bit integer

	@return number
]=]
Reader.Int8 = Int(8)

--[=[
	@method UInt16
	@within Reader

	Reads a 16 bit integer

	@return number
]=]
Reader.Int16 = Int(16)

--[=[
	@method Int8
	@within Reader

	Reads a 24 bit integer

	@return number
]=]
Reader.Int24 = Int(24)

--[=[
	@method Int32
	@within Reader

	Reads a 32 bit integer

	@return number
]=]
Reader.Int32 = Int(32)

--[=[
	@method Float16
	@within Reader

	Reads a half-precision floating point number

	@return number
]=]
Reader.Float16 = Float(5, 10)

--[=[
	@method Float32
	@within Reader

	Reads a single-precision floating point number

	@return number
]=]
Reader.Float32 = Float(8, 23)

--[=[
	@method Float64
	@within Reader

	Reads a double-precision floating point number

	@return number
]=]
Reader.Float64 = Float(11, 52)

return Reader
