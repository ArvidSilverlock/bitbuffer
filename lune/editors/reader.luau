local fs = require("@lune/fs")

local pushIncrementOffset = require("./pushIncrementOffset")
local VALUE_DATA = require("./values.luau")

local READER_CONSTRUCTOR = [[function bitbuffer.reader(b: buffer)
	return setmetatable({
		buffer = b,
		byte = 0,
		bit = 0
	}, Reader)
end]]

local READ_CALLBACKS = {
	String = {
		type = "string",
		callback = [[local length = bitbuffer.readu32(self.buffer, self.byte, self.bit)
local value = bitbuffer.readstring(self.buffer, self.byte + 4, self.bit, length)
self.byte += 4 + length
return value]],
	},
	Boolean = {
		type = "boolean",
		callback = [[local value = bitbuffer.readu1(self.buffer, self.byte, self.bit) == 1
self.bit += 1
if self.bit > 7 then
	self.byte += 1
	self.bit = 0
end
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
		luau:Push(`function Reader:{readType}{width}(): number`, 1)
			:Push(`local value = bitbuffer.read{prefix}{width}(self.buffer, self.byte, self.bit)`)
			:Call(pushIncrementOffset, width)
			:Push("return value")
			:Push(-1, "end")
	end
end

local generateUInt = generateType("UInt")
local generateInt = generateType("Int")
local generateFloat = generateType("Float")

local function insertSimpleValues(luau, typescript)
	for valueType, valueData in VALUE_DATA do
		typescript:Push(`{valueType}: () => {valueType};`)

		local constructor = valueData.Constructor or `{valueType}.new`
		luau:Push(`function Reader:{valueType}(): {valueType}`, 1)

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
				pushIncrementOffset(luau, offset)
				currentOffset, offset = "self.byte, self.bit", 0
			end

			if type(data) == "string" then
				if offset > 0 then
					pushIncrementOffset(luau, offset)
					offset = 0
				end
				luau:Push(`{assignment}self:{data}()`)
			elseif data.type == "Alpha" then
				local divisor = 2 ^ data.width - 1
				luau:Push(`{assignment}bitbuffer.readu{data.width}(self.buffer, {currentOffset}) / {divisor}`)
				offset += data.width
			else
				local prefix = data.type:sub(1, 1):lower()
				luau:Push(`{assignment}bitbuffer.read{prefix}{data.width}(self.buffer, {currentOffset})`)
				offset += data.width
			end
		end

		if offset > 0 then
			pushIncrementOffset(luau, offset)
		end

		-- stylua: ignore
		luau:Break()
			:Push(`return {constructor}({table.concat(variables, ", ")})`)
			:Push(-1, "end")
			:Break()
	end
end

return function(luau, typescript)
	-- stylua: ignore
	typescript
		:Push("declare interface Reader extends Offset {", 1)
		:Push("buffer: buffer;")
		:Break()

	-- stylua: ignore
	luau:Push((getFile("offsetHandler"):gsub("CLASS", "Reader")))
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

	for name, data in READ_CALLBACKS do
		typescript:Push(`{name}: () => {data.type};`)
		-- stylua: ignore
		luau:Push(`function Reader:{name}(): {data.type}`, 1)
			:Push(data.callback)
			:Push(-1, "end")
			:Break()
	end

	luau:Call(insertSimpleValues, typescript):Push(READER_CONSTRUCTOR)

	typescript:Push(-1, "}"):Break()
end
