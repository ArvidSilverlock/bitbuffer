--!native
--!optimize 2
--!strict

local bitbuffer = script.Parent.Parent
local Types = require(bitbuffer.Types)
local Constants = require(bitbuffer.Constants)
local EditorBase = require(bitbuffer.EditorBase)

local CFRAME_SPECIAL_CASES = Constants.CFrameSpecialCases
local POWERS_OF_TWO = Constants.PowersOfTwo
local ENUM_TO_VALUE = Constants.EnumToValue

--[=[
	@class Writer

	Writes values to a buffer, the offset will increment automatically.
]=]
local Writer = setmetatable({}, EditorBase)
Writer.__index = Writer

local function getCFrameSpecialCase(cframe: CFrame): number
	for index, case in CFRAME_SPECIAL_CASES do
		if cframe.Rotation == case then
			return index
		end
	end

	return 0
end

local function handleByteAlignment<T>(
	aligned: Types.BufferWrite<T>?, -- The write function to use when the `offset` is byte aligned
	unaligned: Types.BitBufferWrite<T>, -- The write function to use when the `offset` isn't byte aligned
	totalWidth: number -- The amount of bits modified by the `aligned` function
): Types.BitBufferWrite<T>
	if not aligned then
		return unaligned
	end

	return function(self: Types.Writer, value: T)
		if self._isByteAligned then
			aligned(self._buffer, self._byte, value)
			self:Skip(totalWidth)
		else
			unaligned(self, value)
		end
	end
end

local function UInt(width: number, alignedCallback: Types.BufferWrite<number>?)
	local function unalignedCallback(self, value: number)
		self:UInt(value, width)
	end

	return handleByteAlignment(alignedCallback, unalignedCallback, width)
end

local function Int(width: number, alignedCallback: Types.BufferWrite<number>?)
	local valueCount = 2 ^ width

	local function unalignedCallback(self, value: number)
		self:UInt((value + valueCount) % valueCount, width)
	end

	return handleByteAlignment(alignedCallback, unalignedCallback, width)
end

local function Float(exponentWidth: number, mantissaWidth: number, alignedCallback: Types.BufferWrite<number>?)
	local totalWidth = exponentWidth + mantissaWidth + 1

	local normalToMantissa = 2 ^ (mantissaWidth + 1)
	local subnormalToMantissa = 2 ^ mantissaWidth

	local exponentMax = 2 ^ exponentWidth - 1
	local exponentBias = 2 ^ (exponentWidth - 1) - 2

	-- https://en.wikipedia.org/wiki/Single-precision_floating-point_format#:~:text=(2%20%E2%88%92%202%E2%88%9223)%20%C3%97%202127%20%E2%89%88%203.4028235%20%C3%97%201038
	local valueMax = math.ldexp((2 - 2 ^ -mantissaWidth), (2 ^ (exponentWidth - 1) - 1))

	local function unalignedCallback(self, value: number)
		if math.abs(value) > valueMax then
			self:UInt(0, mantissaWidth, false)
			self:UInt(exponentMax, exponentWidth, false)
			self:UInt(if value < 0 then 1 else 0, 1)
		elseif value ~= value then
			self:UInt(1, mantissaWidth, false)
			self:UInt(exponentMax, exponentWidth, false)
			self:UInt(1, 1)
		elseif value == 0 then
			self:UInt(0, mantissaWidth, false)
			self:UInt(0, exponentWidth, false)
			self:UInt(0, 1)
		else
			local mantissa, exponent = math.frexp(value)
			mantissa = math.abs(mantissa)
			exponent += exponentBias

			if exponent <= 0 then -- Calculate the subnormal mantissa
				local biasShift = math.ldexp(1, math.abs(exponent)) -- 2 ^ exponent
				mantissa = mantissa * subnormalToMantissa / biasShift
			else -- Calculate the normal mantissa
				mantissa *= normalToMantissa
			end

			self:UInt(math.round(mantissa), mantissaWidth, false)
			self:UInt(math.max(exponent, 0), exponentWidth, false)
			self:UInt(if value < 0 then 1 else 0, 1)
		end
	end

	return handleByteAlignment(alignedCallback, unalignedCallback, totalWidth)
end

local function writeString(self, value: string)
	local stringLength = #value
	if self._isByteAligned then
		buffer.writestring(self._buffer, self._byte, value)
		self:Skip(stringLength * 8)
	else
		local stringBuffer = buffer.fromstring(value)

		for stringOffset = 0, stringLength - 1 do
			local byte = buffer.readu8(stringBuffer, stringOffset)
			self:UInt(byte, 8, false)
		end

		self:UpdateByteOffset()
	end
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
	@param updateByteOffset boolean -- Whether or not to update information on the current byte, used internally to reduce unnecessary calculations.
]=]
function Writer:UInt(value: number, width: number, updateByteOffset: boolean?)
	self.write(self._buffer, self._offset, value, width)
	self:Skip(width, updateByteOffset)
end

--[=[
	@method Int
	@within Writer

	Writes a signed integer of any width from 1-53, note that one of these bits is used as the sign

	@param value number
	@param width number
]=]
function Writer:Int(value: number, width: number)
	local valueCount = POWERS_OF_TWO[width]
	self:UInt((value + valueCount) % valueCount, width)
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
	self:UInt(#value, lengthWidth or 16)
	writeString(self, value)
end

--[=[
	@method NullTerminatedString
	@within Writer

	Writes a string then a byte with the value 0 after the string, but doesn't encode the length.
	The `Reader` will read all bytes until a 0 is found.
	
	Note that this assumes there is no character with a value of `0` already present in the string.
	
	@param value string
]=]
function Writer:NullTerminatedString(value: string)
	writeString(self, value)
	self:UInt8(0)
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
	self:UInt(value.Number, 11)
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
	
	Writes an `EnumItem` using two `UInt12`s, will only use 1 if an `enumType` is already specified.

	@param value EnumItem
	@param enumType Enum? -- If specified, it will skip the encoding of the `EnumType`
]=]
function Writer:Enum(value: EnumItem, enumType: Enum?)
	if not enumType then
		self:UInt(ENUM_TO_VALUE[value.EnumType], 12)
	end

	self:UInt(value.Value, 12)
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
Writer.UInt8 = UInt(8, buffer.writeu8)

--[=[
	@method UInt16
	@within Writer

	Writes a 16 bit unsigned integer

	@param value number
]=]
Writer.UInt16 = UInt(16, buffer.writeu16)

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
Writer.UInt32 = UInt(32, buffer.writeu32)

--[=[
	@method Int8
	@within Writer

	Writes an 8 bit signed integer

	@param value number
]=]
Writer.Int8 = Int(8, buffer.writei8)

--[=[
	@method Int16
	@within Writer

	Writes a 16 bit signed integer

	@param value number
]=]
Writer.Int16 = Int(16, buffer.writei16)

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
Writer.Int32 = Int(32, buffer.writei32)

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
Writer.Float32 = Float(8, 23, buffer.writef32)

--[=[
	@method Float64
	@within Writer

	Writes a double-precision floating point number

	@param value number
]=]
Writer.Float64 = Float(11, 52, buffer.writef64)

return Writer
