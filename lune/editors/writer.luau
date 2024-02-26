local fs = require("@lune/fs")

local VALUE_DATA = require("./values.luau")

local WRITER_CONSTRUCTOR = [[function bitbuffer.writer(b: buffer)
	return setmetatable({
		_buffer = b,
		_byte = 0,
		_bit = 0,
	}, Writer)
end]]

local WRITE_CALLBACKS = {
	String = {
		type = "string",
		callback = [[bitbuffer.writeu32(self._buffer, self._byte, self._bit, #value)
bitbuffer.writestring(self._buffer, self._byte + 4, self._bit, value)
self:IncrementOffset(32 + #value * 8)]],
	},
	Boolean = {
		type = "boolean",
		callback = [[bitbuffer.writeu1(self._buffer, self._byte, self._bit, if value then 1 else 0)
self:IncrementOffset(1)]],
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

local function getFile(fileName: string)
	return (fs.readFile(`lune/editors/{fileName}.luau`):gsub("\n$", ""))
end

local function generateType(writeType: "UInt" | "Int" | "Float")
	local prefix = writeType:sub(1, 1):lower()
	return function(luau, typescript, width: number): string
		typescript:Push(`{writeType}{width}: (value: number) => void;`)
		luau:BlockStart(`function Writer:{writeType}{width}(value: number)`)
			:Push(`bitbuffer.write{prefix}{width}(self._buffer, self._byte, self._bit, value)`)
			:Push(`self:IncrementOffset({width})`)
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
				currentOffset = "self._byte, self._bit"
			elseif offset % 8 == 0 then
				currentOffset = `self._byte + {offset // 8}, self._bit`
			else
				luau:Push(`self:IncrementOffset({offset})`)
				currentOffset = "self._byte, self._bit"
				offset = 0
			end

			if type(data) == "string" then
				if offset > 0 then
					luau:Push(`self:IncrementOffset({offset})`)
					offset = 0
				end
				luau:Push(`self:{data}(value.{value})`)
			elseif data.type == "Alpha" then
				local roundedValue = `math.floor(value.{value} * {2 ^ data.width - 1})`
				luau:Push(`bitbuffer.writeu{data.width}(self._buffer, {currentOffset}, {roundedValue})`)
				offset += data.width
			else
				local prefix = data.type:sub(1, 1):lower()
				luau:Push(`bitbuffer.write{prefix}{data.width}(self._buffer, {currentOffset}, value.{value})`)
				offset += data.width
			end
		end

		-- stylua: ignore
		luau:ConditionalPush(offset > 0, `self:IncrementOffset({offset})`)
			:BlockEnd()
			:Push("")
	end
end

return function(luau, typescript)
	typescript
		:BlockStart("declare interface Writer {")
		:Push("IncrementOffset: (amount: number) => void;")
		:Push("SetOffset: (byte: number, bit?: number) => void;")
		:Push("Align: () => void;")
		:Push("")

	luau:Push(getFile("base"):gsub("CLASS", "Writer"), "\n")

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

	-- stylua: ignore
	luau:Call(insertSimpleValues, typescript)
		:Push(WRITER_CONSTRUCTOR)

	typescript:BlockEnd("}"):Push("")
end
