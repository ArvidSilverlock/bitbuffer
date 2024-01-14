--!native
--!optimize 2

type BufferRead<T> = (b: buffer, offset: number) -> T
type BitBufferRead<T> = (self: any) -> T

local bitbuffer = script.Parent.Parent
local Constants = require(bitbuffer.Constants)
local EditorBase = require(bitbuffer.EditorBase)

local CFRAME_SPECIAL_CASES = Constants.CFrameSpecialCases
local ENUM_TO_VALUE = Constants.EnumToValue
local VALUE_TO_ENUM = Constants.ValueToEnum

--[=[
	@class Reader

	Reads values to a buffer, the offset will increment automatically.
]=]
local Reader = setmetatable({}, EditorBase)
Reader.__index = Reader

local function handleByteAlignment<T>(
	aligned: BufferRead<T>?, -- The write function to use when the `offset` is byte aligned
	unaligned: BitBufferRead<T>, -- The write function to use when the `offset` isn't byte aligned
	totalWidth: number -- The amount of bits modified by the `aligned` function
): BitBufferRead<T>
	if not aligned then
		return unaligned
	end

	return function(self)
		if self._isByteAligned then
			local value = aligned(self._buffer, self._byte)
			self:Skip(totalWidth)
			return value
		else
			return unaligned(self)
		end
	end
end

local function UInt(width: number, alignedCallback: BufferRead<number>?): BitBufferRead<number>
	local function unalignedCallback(self): number
		return self:UInt(width)
	end

	return handleByteAlignment(alignedCallback, unalignedCallback, width)
end

local function Int(width: number, alignedCallback: BufferRead<number>?): BitBufferRead<number>
	local valueWidth = width - 1

	local function unalignedCallback(self): number
		local value = self:UInt(valueWidth)
		local sign = self:UInt(1) == 1
		return if sign then -value else value
	end

	return handleByteAlignment(alignedCallback, unalignedCallback, width)
end

local function Float(
	exponentWidth: number,
	mantissaWidth: number,
	alignedCallback: BufferRead<number>?
): BitBufferRead<number>
	local totalWidth = mantissaWidth + exponentWidth + 1

	local normalToMantissa = 2 ^ (mantissaWidth + 1)
	local denormalToMantissa = 2 ^ mantissaWidth

	local exponentMax = 2 ^ exponentWidth - 1
	local exponentBias = 2 ^ (exponentWidth - 1) - 2

	local function unalignedCallback(self): number
		local mantissa = self:UInt(mantissaWidth)
		local exponent = self:UInt(exponentWidth)
		local sign = self:UInt(1) == 1

		if mantissa == 0 and exponent == exponentMax then
			return if sign then -math.huge else math.huge
		elseif mantissa == 1 and exponent == exponentMax then
			return 0 / 0
		elseif mantissa == 0 and exponent == 0 then
			return 0
		else
			if exponent == 0 then -- Calculate the "denormal" mantissa
				mantissa /= denormalToMantissa
			else -- Calculate the normal mantissa
				mantissa = mantissa / normalToMantissa + 0.5
			end

			local value = math.ldexp(mantissa, exponent - exponentBias)
			return if sign then -value else value
		end
	end

	return handleByteAlignment(alignedCallback, unalignedCallback, totalWidth)
end

local function readString(self, length: number): string
	if bit32.band(self._offset, 0b111) == 0 then -- If the `offset` is byte aligned
		local output = buffer.readstring(self._buffer, self._offset, length)
		self._offset += length
		return output
	else
		local stringBuffer = buffer.create(length)
		for stringOffset = 0, length - 1 do
			buffer.writeu8(stringBuffer, stringOffset, self:UInt8())
		end

		return buffer.tostring(stringBuffer)
	end
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

	Reads an unsigned integer of any width from 1-53

	@param width number -- The bit width to read
	@param updateByteOffset boolean? -- Whether or not to update information on the current byte, used internally to reduce unnecessary calculations.

	@return number
]=]
function Reader:UInt(width: number, updateByteOffset: boolean?): number
	local value = self.read(self._buffer, self._offset, width)
	self:Skip(width, updateByteOffset)
	return value
end

--[=[
	@method Int
	@within Reader

	Reads a signed integer of any width from 1-53, note that one of these bits is used as the sign

	@param width number

	@return number
]=]
function Reader:Int(width: number): number
	return self:UInt(width) - math.ldexp(1, width - 1)
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
	return readString(self, stringLength)
end

--[=[
	@method NullTerminatedString
	@within Reader

	Reads infinitely many characters of a string until it encounters a byte with a value of 0

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
	
	Reads an `EnumItem` using two `UInt12`s, will only use 1 if an `enumType` is already specified.

	@param enumType Enum? -- If specified, it will skip the encoding of the `EnumType`

	@return EnumItem
]=]
function Reader:Enum(enumType: Enum?)
	local enumValue = if enumType then ENUM_TO_VALUE[enumType] else self:UInt(12)
	local enumCode = self:UInt(12)

	print(enumValue, enumCode)
	print(VALUE_TO_ENUM[enumValue], VALUE_TO_ENUM[enumValue][enumCode])

	return VALUE_TO_ENUM[enumValue][enumCode]
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
Reader.UInt8 = UInt(8, buffer.readu8)

--[=[
	@method UInt16
	@within Reader

	Reads an 16 bit unsigned integer

	@return number
]=]
Reader.UInt16 = UInt(16, buffer.readu16)

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
Reader.UInt32 = UInt(32, buffer.readu32)

--[=[
	@method UInt8
	@within Reader

	Reads an 8 bit integer

	@return number
]=]
Reader.Int8 = Int(8, buffer.readi8)

--[=[
	@method UInt16
	@within Reader

	Reads a 16 bit integer

	@return number
]=]
Reader.Int16 = Int(16, buffer.readi16)

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
Reader.Int32 = Int(32, buffer.readi32)

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
Reader.Float32 = Float(8, 23, buffer.readf32)

--[=[
	@method Float64
	@within Reader

	Reads a double-precision floating point number

	@return number
]=]
Reader.Float64 = Float(11, 52, buffer.readf64)

return Reader
