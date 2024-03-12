local Snippet = require("../Snippet.luau")

local pushIncrementOffset = require("./pushIncrementOffset")
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
self.byte += 4 + #value]],
	},
	Boolean = {
		type = "boolean",
		callback = [[bitbuffer.writeu1(self.buffer, self.byte, self.bit, if value then 1 else 0)
self.bit += 1
if self.bit > 7 then
	self.byte += 1
	self.bit = 0
end]],
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
		luau:Push(`function Writer:{writeType}{width}(value: number)`, 1)
			:Push(`bitbuffer.write{prefix}{width}(self.buffer, self.byte, self.bit, value)`)
			:Call(pushIncrementOffset, width)
			:Push(-1, "end")
	end
end

local generateUInt = generateType("UInt")
local generateInt = generateType("Int")
local generateFloat = generateType("Float")

local function insertSimpleValues(luau, typescript)
	for valueType, valueData in VALUE_DATA do
		typescript:Push(`{valueType}: (value: {valueType}) => void;`)
		luau:Push(`function Writer:{valueType}(value: {valueType})`, 1)

		local offset = 0
		for _, value in valueData.Values do
			local data = valueData.Types[value]

			local currentOffset
			if offset == 0 then
				currentOffset = "self.byte, self.bit"
			elseif offset % 8 == 0 then
				currentOffset = `self.byte + {offset // 8}, self.bit`
			else
				pushIncrementOffset(luau, offset)
				currentOffset, offset = "self.byte, self.bit", 0
			end

			if type(data) == "string" then
				if offset > 0 then
					pushIncrementOffset(luau, offset)
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
		luau:ConditionalCall(offset > 0, pushIncrementOffset, offset)
			:Push(-1, "end")
			:Break()
	end
end

return function(luau, typescript)
	-- stylua: ignore
	typescript
		:Push("declare interface Writer extends Offset {", 1)
		:Push("buffer: buffer;")
		:Break()

	-- stylua: ignore
	luau:Push("local Writer = bitbuffer.offset()")
		:Break()
		:Push(WRITER_CONSTRUCTOR)
		:Break()

	for width = 1, 53 do
		luau:Call(generateUInt, typescript, width):Break()
	end
	typescript:Break()

	for width = 1, 53 do
		luau:Call(generateInt, typescript, width):Break()
	end
	typescript:Break()

	luau:Call(generateFloat, typescript, 16)
		:Break()
		:Call(generateFloat, typescript, 32)
		:Break()
		:Call(generateFloat, typescript, 64)
		:Break()

	typescript:Break()

	for name, data in WRITE_CALLBACKS do
		typescript:Push(`{name}: (value: {data.type}) => void;`)
		-- stylua: ignore
		luau:Push(`function Writer:{name}(value: {data.type})`, 1)
			:Push(data.callback)
			:Push(-1, "end")
			:Break()
	end

	luau:Call(insertSimpleValues, typescript)

	typescript:Push(-1, "}"):Break()
end
