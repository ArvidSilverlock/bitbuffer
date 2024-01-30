local VALUE_DATA = require("./values.luau")

local READER_CONSTRUCTOR = [[function bitbuffer.reader(b: buffer)
	return setmetatable({
		_buffer = b,
		_offset = 0
	}, Reader)
end]]

local UINT_FORMAT = `bitbuffer.readu%d(self._buffer, self._offset // 8, self._offset %% 8)`
local INT_FORMAT = `bitbuffer.readi%d(self._buffer, self._offset // 8, self._offset %% 8)`
local FLOAT_FORMAT = `bitbuffer.readf%d(self._buffer, self._offset)`
local ALPHA_FORMAT = "bitbuffer.readu%d(self._buffer, self._offset // 8, self._offset %% 8) / %d"

local numberFormats = {
	UInt = UINT_FORMAT,
	Int = INT_FORMAT,
	Float = FLOAT_FORMAT,
}

local function generateType(readType: "UInt" | "Int" | "Float")
	local format = numberFormats[readType]
	return function(width: number): string
		local body = {}

		table.insert(body, `function Reader:{readType}{width}(): number`)
		table.insert(body, `\tlocal value = {format:format(width)}`)
		table.insert(body, `\tself:IncrementOffset({width})`)
		table.insert(body, `\treturn value`)
		table.insert(body, "end")

		return table.concat(body, "\n")
	end
end

local generateUInt = generateType("UInt")
local generateInt = generateType("Int")
local generateFloat = generateType("Float")

local function insertSimpleValues(output)
	for valueType, valueData in VALUE_DATA do
		local body = {}

		local constructor = valueData.Constructor or `{valueType}.new`
		table.insert(body, `function Reader:{valueType}(): {valueType}`)

		local variables = {}

		for index, value in valueData.Values do
			local data = valueData.Types[value]

			local variableName = value:gsub("^%u", string.lower)
			table.insert(variables, variableName)

			local line
			if type(data) == "string" then
				line = `local {variableName} = self:{data}()`
			elseif data.type == "Alpha" then
				line = `local {variableName} = {ALPHA_FORMAT:format(data.width, 2 ^ data.width - 1)}`
			elseif numberFormats[data.type] then
				line = `local {variableName} = {numberFormats[data.type]:format(data.width)}`
			end

			table.insert(body, `\t{line}`)
			if type(data) ~= "string" then
				table.insert(
					body,
					if index ~= #valueData.Values
						then `\tself._offset += {data.width}`
						else `\tself:IncrementOffset({data.width})`
				)
			end
		end

		table.insert(body, "")
		table.insert(body, `\treturn {constructor}({table.concat(variables, ", ")})`)
		table.insert(body, "end")

		table.insert(output, table.concat(body, "\n"))
	end
end

return function()
	local output = {}

	table.insert(output, "local Reader = {}\nReader.__index = Reader")

	for width = 1, 53 do
		table.insert(output, generateUInt(width))
	end

	for width = 2, 52 do
		table.insert(output, generateInt(width))
	end

	table.insert(output, generateFloat(32))
	table.insert(output, generateFloat(64))

	insertSimpleValues(output)

	table.insert(output, READER_CONSTRUCTOR)

	return output
end
