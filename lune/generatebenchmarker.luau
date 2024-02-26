local Snippet = require("./Snippet.luau")
local fs = require("@lune/fs")

local output = Snippet.new()

output
	:Push("--!native")
	:Push("--!optimize 2")
	:Push("")
	:Push("local TEST_BUFFER = buffer.create(2^16 + 1)")
	:Push("local TEST_COUNT = 100_000")
	:Push("local STRING_TEST_COUNT = 1_000")
	:Push("")
	:Push("local bitbuffer = require(workspace.ModuleScript)")
	:Push("")
	:Push("local uBenchmarks, iBenchmarks, fBenchmarks, sBenchmarks = {}, {}, {}, {}")
	:Push("")

local function benchmarkNumber(numberType: "u" | "i" | "f")
	if numberType == "f" then
		output:BlockStart("for _, width in { 16, 32, 64 } do")
	else
		output:BlockStart("for width = 1, 53 do")
	end

	local times = {}
	for _, mode in { "read", "write" } do
		if numberType == "f" then
			output:Push(`local callback = bitbuffer[\`{mode}f\{width}\`]`)
		else
			output:Push(`local callback = bitbuffer.{mode}{numberType}[width]`)
		end

		output
			:Push(`local {mode}StartTime = os.clock()`)
			:BlockStart("for offset = 0, 7 do")
			:BlockStart("for _ = 1, TEST_COUNT do")
			:Push(`callback(TEST_BUFFER, 0, offset{if mode == "write" then ", 0" else ""})`)
			:BlockEnd()
			:BlockEnd()
			:Push(`local {mode}EndTime = os.clock()`)
			:Push("")

		times[mode] = `( {mode}EndTime - {mode}StartTime ) / 8 / TEST_COUNT`
	end

	output
		:Push(`table.insert({numberType}Benchmarks, \{ tostring(width), {times.read}, {times.write} \})`)
		:Push(`print(\`Benchmarked {numberType}\{width}\`)`)
		:Push("task.wait()")
		:BlockEnd()
		:Push("")
end

benchmarkNumber("u")
benchmarkNumber("i")
benchmarkNumber("f")

output
	:BlockStart(`for width = 0, 16 do`)
	:Push("local count = 2 ^ width")
	:Push(`local b = buffer.create(count)`)
	:Push("buffer.fill(b, 0, 0b01100110) -- arbitrary value")
	:Push("local str = buffer.tostring(b)")
	:Push("")

local times = {}
for _, mode in { "read", "write" } do
	output
		:Push(`local {mode}StartTime = os.clock()`)
		:BlockStart("for _ = 1, STRING_TEST_COUNT do")
		:BlockStart("for offset = 1, 7 do")
		:Push(`bitbuffer.{mode}string(TEST_BUFFER, 0, offset{if mode == "write" then ", str" else ""}, count)`)
		:BlockEnd()
		:BlockEnd()
		:Push(`local {mode}EndTime = os.clock()`)
		:Push("")

	times[mode] = `( {mode}EndTime - {mode}StartTime ) / 7 / STRING_TEST_COUNT`
end

output
	:Push(`table.insert(sBenchmarks, \{ tostring(count), {times.read}, {times.write} \})`)
	:Push("print(`Benchmarked string (#{count})`)")
	:Push("task.wait()")
	:BlockEnd()
	:Push("")

output:Push([[
	
local function formatTime(t: number): string
	return if t < 1e-7 then string.format("%.4f ns", t * 1e9)
		elseif t < 1e-4 then string.format("%.4f μs", t * 1e6)
		else string.format("%.4f ms", t * 1e3)
end

local function outputReadWriteTable(tableName, data)
	local output = {}

	local maxName, maxReadTime, maxWriteTime = #tableName, #"read", #"write"
	local formattedData = {}

	for index, value in data do
		local name, readTime, writeTime = value[1], formatTime(value[2]), formatTime(value[3])
		formattedData[index] = { name = name, readTime = readTime, writeTime = writeTime }
		
		maxName = math.max(utf8.len(name), maxName)
		maxReadTime = math.max(utf8.len(readTime), maxReadTime)
		maxWriteTime = math.max(utf8.len(writeTime), maxWriteTime)
	end

	table.insert(output, `┌{string.rep("─", maxName + 2)}┬{string.rep("─", maxReadTime + 2)}┬{string.rep("─", maxWriteTime + 2)}┐`)
	table.insert(output, `│ {tableName}{string.rep(" ", maxName - #tableName)} │ read{string.rep(" ", maxReadTime - 4)} │ write{string.rep(" ", maxWriteTime - 5)} │`)
	table.insert(output, `├{string.rep("─", maxName + 2)}┼{string.rep("─", maxReadTime + 2)}┼{string.rep("─", maxWriteTime + 2)}┤`)

	for _, benchmarkData in formattedData do
		local name, readTime, writeTime = benchmarkData.name, benchmarkData.readTime, benchmarkData.writeTime
		
		local namePadding = string.rep(" ", maxName - utf8.len(name))
		local readPadding = string.rep(" ", maxReadTime - utf8.len(readTime))
		local writePadding = string.rep(" ", maxWriteTime - utf8.len(writeTime))

		table.insert(output, `│ {name}{namePadding} │ {readTime}{readPadding} │ {writeTime}{writePadding} │`)
	end

	table.insert(output, `└{string.rep("─", maxName + 2)}┴{string.rep("─", maxReadTime + 2)}┴{string.rep("─", maxWriteTime + 2)}┘`)
	return output
end

local function merge(...: any)
	local output = {}
	local leftPadding = ""
	
	for inputIndex = 1, select("#", ...) do
		local value = select(inputIndex, ...)
		local rightPadding = string.rep(" ", if value[1] then utf8.len(value[1]) else 0)

		for lineIndex = 1, math.max(#output, #value) do
			output[lineIndex] = ( output[lineIndex] or leftPadding ) .. " " .. (value[lineIndex] or rightPadding)
		end

		leftPadding ..= " " .. rightPadding
	end
	
	return output
end

local uint = outputReadWriteTable("u", uBenchmarks)
local int = outputReadWriteTable("i", iBenchmarks)
local float = outputReadWriteTable("f", fBenchmarks)
local string = outputReadWriteTable("string", sBenchmarks)

print("\n" .. table.concat(merge(uint, int, float, string), "\n"))]])

local luauSource = tostring(output):gsub("\n%s+\n", "\n\n")
fs.writeFile("./lune/benchmark.luau", luauSource)
