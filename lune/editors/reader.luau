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
	String = {
		type = "string",
		callback = [[local length = bitbuffer.readu32(self._buffer, self._byte, self._bit)
local value = bitbuffer.readstring(self._buffer, self._byte + 4, self._bit, length)
self:IncrementOffset(32 + length * 8)
return value]],
	},
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
	return function(luau, typescript, width: number): string
		typescript:Push(`{readType}{width}: () => number;`)
		luau:BlockStart(`function Reader:{readType}{width}(): number`)
			:Push(`local value = bitbuffer.read{prefix}{width}(self._buffer, self._byte, self._bit)`)
			:Push(`self:IncrementOffset({width})`)
			:Push("return value")
			:BlockEnd()
	end
end

local generateUInt = generateType("UInt")
local generateInt = generateType("Int")
local generateFloat = generateType("Float")

local function insertSimpleValues(luau, typescript)
	for valueType, valueData in VALUE_DATA do
		typescript:Push(valueType, ": () => ", valueType, ";")

		local constructor = valueData.Constructor or `{valueType}.new`
		luau:BlockStart(`function Reader:{valueType}(): {valueType}`)

		local variables = {}

		local offset = 0
		for _, value in valueData.Values do
			local data = valueData.Types[value]

			local variableName = value:gsub("^%u", string.lower)
			local assignment = `local {variableName} = `

			table.insert(variables, variableName)

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
				luau:Push(assignment, `self:{data}()`)
			elseif data.type == "Alpha" then
				local divisor = 2 ^ data.width - 1
				luau:Push(assignment, `bitbuffer.readu{data.width}(self._buffer, {currentOffset}) / {divisor}`)
				offset += data.width
			else
				local prefix = data.type:sub(1, 1):lower()
				luau:Push(assignment, `bitbuffer.read{prefix}{data.width}(self._buffer, {currentOffset})`)
				offset += data.width
			end
		end

		if offset > 0 then
			luau:Push(`self:IncrementOffset({offset})`)
		end

		-- stylua: ignore
		luau:Push("")
			:Push(`return {constructor}({table.concat(variables, ", ")})`)
			:BlockEnd()
			:Push("")
	end
end

return function(luau, typescript)
	typescript
		:BlockStart("declare interface Reader {")
		:Push("IncrementOffset: (amount: number) => void;")
		:Push("SetOffset: (byte: number, bit?: number) => void;")
		:Push("Align: () => void;")
		:Push("")

	luau:Push(getFile("base"):gsub("CLASS", "Reader"), "\n")

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

	for name, data in READ_CALLBACKS do
		typescript:Push(name, ": () => ", data.type, ";")
		-- stylua: ignore
		luau:BlockStart(`function Reader:{name}(): {data.type}`)
			:Push(data.callback)
			:BlockEnd()
			:Push("")
	end

	-- stylua: ignore
	luau:Call(insertSimpleValues, typescript)
		:Push(READER_CONSTRUCTOR)

	typescript:BlockEnd("}"):Push("")
end
