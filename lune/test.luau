local bitbuffer = require("../src/init.luau")
local fs = require("@lune/fs")

local b = buffer.create(2 ^ 16)

local TEST_COUNT = 128

local function random(min: number, max: number): number
	return math.random() * (max - min) + min
end

local function randomString(): (string, number)
	local length = math.random(1, 256)
	local str = buffer.create(length)

	for offset = 0, length - 1 do
		buffer.writeu8(str, offset, math.random(0, 255))
	end

	return buffer.tostring(str), length
end

local function test(name: string, read, write, round)
	return function(value: number, ...: any)
		local rounded = if round then round(value) else value
		for offset = 0, 7 do
			write(b, 0, offset, rounded, ...)
			local readOutput = read(b, 0, offset, ...)
			if readOutput ~= rounded then
				error(`read/write {name} failed on offset {offset} for the value {rounded} (got {readOutput})`)
			end
		end
	end
end

local function testbase(tobase, frombase, testTable: { [string]: string })
	local function executeTest(input: string, correctEncoded: string?)
		local encoded = tobase(buffer.fromstring(input))
		local decoded = buffer.tostring(frombase(encoded))

		assert(decoded == input, `'{encoded}' failed to decode into '{input}' (got '{decoded}')`)
		if encoded then
			assert(encoded == encoded, `'{input}' failed to encode into '{correctEncoded}' (got '{encoded}')`)
		end
	end

	for correct, encoded in testTable do
		executeTest(correct, encoded)
	end

	for _ = 1, TEST_COUNT do
		local str = randomString()
		executeTest(str)
	end
end

local function getFiles(directory, output)
	output = output or {}
	for _, name in fs.readDir(directory) do
		local path = `{directory}/{name}`
		if fs.isFile(path) then
			table.insert(output, path)
		else
			getFiles(path, output)
		end
	end

	return output
end

local responses = {}

local maxNameLength = 0
local maxResponseLength = 0

for _, testPath in getFiles("lune/tests") do
	local testName = testPath:match("([%w_]+)%.luau$")
	if not testName then
		continue
	end

	local testFunction = require(testPath:gsub("^lune/", ""))

	local success, response = pcall(testFunction, b, bitbuffer, test, testbase, random, randomString, TEST_COUNT)
	local formattedResponse = if response
		then response
			:gsub('%[string ".*/bitbuffer/(.*)"%]:(%d+): (.+)', "%1 (line %2): %3")
			:gsub('%[string "lune/test"%]:(%d+): (.+)', "lune/test.luau (line %1): %2")
		else ""

	table.insert(responses, { name = testName, status = success, response = formattedResponse })

	maxNameLength = math.max(#testName, maxNameLength)
	maxResponseLength = math.max(#formattedResponse, maxResponseLength)
end

local preLine = if maxResponseLength > 0
	then `┌─{string.rep("─", maxNameLength)}─┬─{string.rep("─", maxResponseLength)}─┬───┐`
	else `┌─{string.rep("─", maxNameLength)}─┬───┐`

local postLine = if maxResponseLength > 0
	then `└─{string.rep("─", maxNameLength)}─┴─{string.rep("─", maxResponseLength)}─┴───┘`
	else `└─{string.rep("─", maxNameLength)}─┴───┘`

local output = {}

table.insert(output, preLine)
for _, response in responses do
	local formattedLine

	local namePadding = string.rep(" ", maxNameLength - #response.name)
	local statusIcon = if response.status then "✓" else "✗"

	-- Would've used `string.format`, but this doesn't work for large amounts of padding (i.e., 100 characters or so)
	if maxResponseLength > 0 then
		local responsePadding = string.rep(" ", maxResponseLength - #response.response)
		formattedLine = `│ {response.name}{namePadding} │ {response.response}{responsePadding} │ {statusIcon} │`
	else
		formattedLine = `│ {response.name}{namePadding} │ {statusIcon} │`
	end

	table.insert(output, formattedLine)
end
table.insert(output, postLine)

print(table.concat(output, "\n"))
