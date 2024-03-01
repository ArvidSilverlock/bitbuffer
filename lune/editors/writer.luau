local fs = require("@lune/fs")

local VALUE_DATA = require("./values.luau")

local WRITER_CONSTRUCTOR = [[function bitbuffer.writer(b: buffer)
	return setmetatable({
		buffer = b,
		byte = 0,
		bit = 0,
	}, Writer)
end]]

local WRITE_CALLBACKS = {
	String = {
		type = "string",
		callback = [[bitbuffer.writeu32(self.buffer, self.byte, self.bit, #value)
bitbuffer.writestring(self.buffer, self.byte + 4, self.bit, value)
self:IncrementOffset(4 + #value, 0)]],
	},
	Boolean = {
		type = "boolean",
		callback = [[bitbuffer.writeu1(self.buffer, self.byte, self.bit, if value then 1 else 0)
self:IncrementOffset(0, 1)]],
	},
	CFrame = {
		type = "CFrame",
		callback = [[local specialCase = table.find(CFRAME_SPECIAL_CASES, value.Rotation) or 0
self:UInt5(specialCase)
		
self:Vector3(value.Position)
if specialCase == 0 then
	local axis, angle = value:ToAxisAngle()
	self:Vector3(axis * angle)
end]],
	},
	LosslessCFrame = {
		type = "CFrame",
		callback = [[local specialCase = table.find(CFRAME_SPECIAL_CASES, value.Rotation) or 0
self:UInt5(specialCase)
		
self:Vector3(value.Position)
if specialCase == 0 then
	self:Vector3(value.XVector)
	self:Vector3(value.YVector)
	self:Vector3(value.ZVector)
end]],
	},
	NumberSequence = {
		type = "NumberSequence",
		callback = [[self:UInt5(#value.Keypoints) -- max length of 20, tested
for _, keypoint in value.Keypoints do
	self:NumberSequenceKeypoint(keypoint)
end]],
	},
	ColorSequence = {
		type = "ColorSequence",
		callback = [[self:UInt5(#value.Keypoints) -- max length of 20, tested
for _, keypoint in value.Keypoints do
	self:ColorSequenceKeypoint(keypoint)
end]],
	},
}

local function generateType(writeType: "UInt" | "Int" | "Float")
	local prefix = writeType:sub(1, 1):lower()
	return function(luau, typescript, width: number): string
		typescript:Push(`{writeType}{width}: (value: number) => void;`)
		luau:BlockStart(`function Writer:{writeType}{width}(value: number)`)
			:Push(`bitbuffer.write{prefix}{width}(self.buffer, self.byte, self.bit, value)`)
			:Push(`self:IncrementOffset({width // 8}, {width % 8})`)
			:BlockEnd()
	end
end

local generateUInt = generateType("UInt")
local generateInt = generateType("Int")
local generateFloat = generateType("Float")

local function insertSimpleValues(luau, typescript)
	for valueType, valueData in VALUE_DATA do
		typescript:Push(`{valueType}: (value: {valueType}) => void;`)
		luau:BlockStart(`function Writer:{valueType}(value: {valueType})`)

		local offset = 0
		for _, value in valueData.Values do
			local data = valueData.Types[value]

			local currentOffset
			if offset == 0 then
				currentOffset = "self.byte, self.bit"
			elseif offset % 8 == 0 then
				currentOffset = `self.byte + {offset // 8}, self.bit`
			else
				luau:Push(`self:IncrementOffset({offset // 8}, {offset % 8})`)
				currentOffset = "self.byte, self.bit"
				offset = 0
			end

			if type(data) == "string" then
				if offset > 0 then
					luau:Push(`self:IncrementOffset({offset // 8}, {offset % 8})`)
					offset = 0
				end
				luau:Push(`self:{data}(value.{value})`)
			elseif data.type == "Alpha" then
				local roundedValue = `math.floor(value.{value} * {2 ^ data.width - 1})`
				luau:Push(`bitbuffer.writeu{data.width}(self.buffer, {currentOffset}, {roundedValue})`)
				offset += data.width
			else
				local prefix = data.type:sub(1, 1):lower()
				luau:Push(`bitbuffer.write{prefix}{data.width}(self.buffer, {currentOffset}, value.{value})`)
				offset += data.width
			end
		end

		-- stylua: ignore
		luau:ConditionalPush(offset > 0, `self:IncrementOffset({offset // 8}, {offset % 8})`)
			:BlockEnd()
			:Push("")
	end
end

return function(luau, typescript)
	-- stylua: ignore
	typescript
		:BlockStart("declare interface Writer extends Offset {")
		:Push("buffer: buffer;")
		:Push("")

	-- stylua: ignore
	luau:Push("local Writer = bitbuffer.offset()")
		:Push("")
		:Push(WRITER_CONSTRUCTOR)
		:Push("")

	for width = 1, 53 do
		luau:Call(generateUInt, typescript, width):Push("")
	end
	typescript:Push("")

	for width = 1, 53 do
		luau:Call(generateInt, typescript, width):Push("")
	end
	typescript:Push("")

	luau:Call(generateFloat, typescript, 16)
		:Push("")
		:Call(generateFloat, typescript, 32)
		:Push("")
		:Call(generateFloat, typescript, 64)
		:Push("")

	typescript:Push("")

	for name, data in WRITE_CALLBACKS do
		typescript:Push(`{name}: (value: {data.type}) => void;`)
		-- stylua: ignore
		luau:BlockStart(`function Writer:{name}(value: {data.type})`)
			:Push(data.callback)
			:BlockEnd()
			:Push("")
	end

	luau:Call(insertSimpleValues, typescript)

	typescript:BlockEnd("}"):Push("")
end
