local Snippet = require("../Snippet.luau")
local fs = require("@lune/fs")

local VALUE_DATA = require("./values.luau")

local READER_CONSTRUCTOR = [[function bitbuffer.reader(b: buffer)
	return setmetatable({
		_buffer = b,
		_byte = 0,
		_bit = 0,
	}, Reader)
end]]

local READ_CALLBACKS = {
	Boolean = {
		type = "boolean",
		callback = [[local value = bitbuffer.readu1(self._buffer, self._byte, self._bit) == 1
self:IncrementOffset(1)
return value]],
	},
	CFrame = {
		type = "CFrame",
		callback = [[local specialCase = self:UInt5()
local position = self:Vector3()
	
if specialCase == 0 then
	local axisAngle = self:Vector3()
	return CFrame.fromAxisAngle(axisAngle, axisAngle.Magnitude) + position
else
	local specialCase = CFRAME_SPECIAL_CASES[specialCase]
	return CFrame.fromMatrix(position, specialCase.XVector, specialCase.YVector, specialCase.ZVector)
end]],
	},
	LosslessCFrame = {
		type = "CFrame",
		callback = [[local specialCase = self:UInt5()
local position = self:Vector3()
	
if specialCase == 0 then
	return CFrame.fromMatrix(position, self:Vector3(), self:Vector3(), self:Vector3())
else
	local specialCase = CFRAME_SPECIAL_CASES[specialCase]
	return CFrame.fromMatrix(position, specialCase.XVector, specialCase.YVector, specialCase.ZVector)
end]],
	},
	NumberSequence = {
		type = "NumberSequence",
		callback = [[local length = self:UInt5() -- max length of 20, tested
local keypoints = table.create(length)
	
for _ = 1, length do
	local keypoint = self:NumberSequenceKeypoint()
	table.insert(keypoints, keypoint)
end
	
return NumberSequence.new(keypoints)]],
	},
	ColorSequence = {
		type = "ColorSequence",
		callback = [[local length = self:UInt5() -- max length of 20, tested
local keypoints = table.create(length)
	
for _ = 1, length do
	local keypoint = self:ColorSequenceKeypoint()
	table.insert(keypoints, keypoint)
end
	
return ColorSequence.new(keypoints)]],
	},
}

local function getFile(fileName: string)
	return (fs.readFile(`lune/editors/{fileName}.luau`):gsub("\n$", ""))
end

local function generateType(readType: "UInt" | "Int" | "Float")
	local prefix = readType:sub(1, 1):lower()
	return function(width: number, tsOutput): string
		tsOutput:Push(readType, width, ": () => number;")

		local body = Snippet.new()

		body:Push("function Reader:", readType, width, "(): number")
		body:Push("\tlocal value = bitbuffer.read", prefix, width, "(self._buffer, self._byte, self._bit)")
		body:Push("\tself:IncrementOffset(", width, ")")
		body:Push("\treturn value")
		body:Push("end")

		return tostring(body)
	end
end

local generateUInt = generateType("UInt")
local generateInt = generateType("Int")
local generateFloat = generateType("Float")

local function insertSimpleValues(output, tsOutput)
	for valueType, valueData in VALUE_DATA do
		local body = Snippet.new()

		tsOutput:Push(valueType, ": () => ", valueType, ";")

		local constructor = valueData.Constructor or `{valueType}.new`
		body:Push("function Reader:", valueType, "(): ", valueType)

		local variables = {}

		local offset = 0
		for _, value in valueData.Values do
			local data = valueData.Types[value]

			local variableName = value:gsub("^%u", string.lower)
			table.insert(variables, variableName)

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
				line = `self:{data}()`
			elseif data.type == "Alpha" then
				line = `bitbuffer.readu{data.width}(self._buffer, {currentOffset}) / {2 ^ data.width - 1}`
				offset += data.width
			else
				local prefix = data.type:sub(1, 1):lower()
				line = `bitbuffer.read{prefix}{data.width}(self._buffer, {currentOffset})`
				offset += data.width
			end

			table.insert(body, `\tlocal {variableName} = {line}`)
		end

		if offset > 0 then
			table.insert(body, `\tself:IncrementOffset({offset})`)
		end

		table.insert(body, "")
		table.insert(body, `\treturn {constructor}({table.concat(variables, ", ")})`)
		table.insert(body, "end")

		table.insert(output, tostring(body))
	end
end

return function()
	local output = {}
	local tsOutput = Snippet.new()

	tsOutput:Push("IncrementOffset: (amount: number) => void;")
	tsOutput:Push("SetOffset: (byte: number, bit?: number) => void;")
	tsOutput:Push("Align: () => void;")
	tsOutput:Push("")

	table.insert(output, (getFile("base"):gsub("CLASS", "Reader")))

	for width = 1, 53 do
		table.insert(output, generateUInt(width, tsOutput))
	end
	tsOutput:Push("")

	for width = 2, 52 do
		table.insert(output, generateInt(width, tsOutput))
	end
	tsOutput:Push("")

	table.insert(output, generateFloat(16, tsOutput))
	table.insert(output, generateFloat(32, tsOutput))
	table.insert(output, generateFloat(64, tsOutput))
	tsOutput:Push("")

	for name, data in READ_CALLBACKS do
		local body = Snippet.new()
		tsOutput:Push(name, ": () => ", data.type, ";")
		body:Push("function Reader:", name, "(): ", data.type)
		body:Push(data.callback):Indent()
		body:Push("end")
		table.insert(output, tostring(body))
	end

	insertSimpleValues(output, tsOutput)

	table.insert(output, READER_CONSTRUCTOR)

	tsOutput:Indent()
	tsOutput:Insert(1, "declare interface Reader {")
	tsOutput:Push("}")

	return output, tostring(tsOutput)
end
