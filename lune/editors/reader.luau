local fs = require("@lune/fs")

local VALUE_DATA = require("./values.luau")

local READER_CONSTRUCTOR = [[function bitbuffer.reader(b: buffer)
	return setmetatable({
		buffer = b,
		byte = 0,
		bit = 0
	}, Reader)
end

function Reader:__index(index)
	return Reader[index] or bitbuffer.offset[index]
end]]

local READ_CALLBACKS = {
	String = {
		type = "string",
		callback = [[local length = bitbuffer.readu32(self.buffer, self.byte, self.bit)
local value = bitbuffer.readstring(self.buffer, self.byte + 4, self.bit, length)
self:IncrementOffset(4 + length, 0)
return value]],
	},
	Boolean = {
		type = "boolean",
		callback = [[local value = bitbuffer.readu1(self.buffer, self.byte, self.bit) == 1
self:IncrementOffset(0, 1)
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

local function generateType(readType: "UInt" | "Int" | "Float")
	local prefix = readType:sub(1, 1):lower()
	return function(luau, typescript, width: number): string
		typescript:Push(`{readType}{width}: () => number;`)
		luau:BlockStart(`function Reader:{readType}{width}(): number`)
			:Push(`local value = bitbuffer.read{prefix}{width}(self.buffer, self.byte, self.bit)`)
			:Push(`self:IncrementOffset({width // 8}, {width % 8})`)
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
				luau:Push(assignment, `self:{data}()`)
			elseif data.type == "Alpha" then
				local divisor = 2 ^ data.width - 1
				luau:Push(assignment, `bitbuffer.readu{data.width}(self.buffer, {currentOffset}) / {divisor}`)
				offset += data.width
			else
				local prefix = data.type:sub(1, 1):lower()
				luau:Push(assignment, `bitbuffer.read{prefix}{data.width}(self.buffer, {currentOffset})`)
				offset += data.width
			end
		end

		if offset > 0 then
			luau:Push(`self:IncrementOffset({offset // 8}, {offset % 8})`)
		end

		-- stylua: ignore
		luau:Push("")
			:Push(`return {constructor}({table.concat(variables, ", ")})`)
			:BlockEnd()
			:Push("")
	end
end

return function(luau, typescript)
	-- stylua: ignore
	typescript
		:BlockStart("declare interface Reader extends Offset {")
		:Push("buffer: buffer;")
		:Push("")

	-- stylua: ignore
	luau:Push("local Reader = bitbuffer.offset()")
		:Push("")
		:Push(READER_CONSTRUCTOR)
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

	for name, data in READ_CALLBACKS do
		typescript:Push(name, ": () => ", data.type, ";")
		-- stylua: ignore
		luau:BlockStart(`function Reader:{name}(): {data.type}`)
			:Push(data.callback)
			:BlockEnd()
			:Push("")
	end

	luau:Call(insertSimpleValues, typescript)

	typescript:BlockEnd("}"):Push("")
end
