local Snippet = require("../Snippet.luau")
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
		callback = [[self:UInt(#value.Keypoints, 5) -- max length of 20, tested
for _, keypoint in value.Keypoints do
	self:NumberSequenceKeypoint(keypoint)
end]],
	},
	ColorSequence = {
		type = "ColorSequence",
		callback = [[self:UInt(#value.Keypoints, 5) -- max length of 20, tested
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
	return function(width: number): string
		local body = Snippet.new()

		body:Push("function Writer:", writeType, width, "(value: number)")
		body:Push("\tbitbuffer.write", prefix, width, "(self._buffer, self._byte, self._bit, value)")
		body:Push("\tself:IncrementOffset(", width, ")")
		body:Push("end")

		return tostring(body)
	end
end

local generateUInt = generateType("UInt")
local generateInt = generateType("Int")
local generateFloat = generateType("Float")

local function insertSimpleValues(output)
	for valueType, valueData in VALUE_DATA do
		local body = Snippet.new()

		local constructor = valueData.Constructor or `{valueType}.new`
		body:Push("function Writer:", valueType, "(value: ", valueType, ")")

		local variables = {}

		local offset = 0
		for _, value in valueData.Values do
			local data = valueData.Types[value]

			local variableName = `value.{value}`

			local currentOffset
			local line

			if offset == 0 then
				currentOffset = "self._byte, self._bit"
			elseif offset % 8 == 0 then
				currentOffset = `self._byte + {offset // 8}, self._bit`
			else
				body:Push("\tself:IncrementOffset(", offset, ")")
				offset = 0
				currentOffset = "self._byte, self._bit"
			end

			if type(data) == "string" then
				if offset > 0 then
					body:Push("\tself:IncrementOffset(", offset, ")")
					offset = 0
				end
				line = `self:{data}(value.{value})`
			elseif data.type == "Alpha" then
				line =
					`bitbuffer.writeu{data.width}(self._buffer, {currentOffset}, math.floor(value.{value} * {2 ^ data.width - 1}))`
				offset += data.width
			else
				local prefix = data.type:sub(1, 1):lower()
				line = `bitbuffer.write{prefix}{data.width}(self._buffer, {currentOffset}, value.{value})`
				offset += data.width
			end

			table.insert(body, `\t{line}`)
		end

		if offset > 0 then
			table.insert(body, `\tself:IncrementOffset({offset})`)
		end

		table.insert(body, "end")

		table.insert(output, tostring(body))
	end
end

return function()
	local output = {}

	table.insert(output, "local Writer = {}\nWriter.__index = Writer")

	table.insert(output, (getFile("base"):gsub("CLASS", "Writer")))

	for width = 1, 53 do
		table.insert(output, generateUInt(width))
	end

	for width = 2, 52 do
		table.insert(output, generateInt(width))
	end

	table.insert(output, generateFloat(32))
	table.insert(output, generateFloat(64))

	for name, data in WRITE_CALLBACKS do
		local body = Snippet.new()
		body:Push("function Writer:", name, "(value: ", data.type, ")")
		body:Push(data.callback):Indent()
		body:Push("end")
		table.insert(output, tostring(body))
	end

	insertSimpleValues(output)

	table.insert(output, WRITER_CONSTRUCTOR)

	return output
end
