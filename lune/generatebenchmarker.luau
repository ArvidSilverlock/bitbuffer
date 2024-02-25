local Snippet = require("./Snippet/init.luau")
local fs = require("@lune/fs")

local output = Snippet.new()

output:Push("--!native")
output:Push("--!optimize 2")
output:Push("")

output:Push("local TEST_BUFFER = buffer.create(16)")
output:Push("local TEST_COUNT = 100_000")
output:Push("")

output:Push("local bitbuffer = require(workspace.ModuleScript)")
output:Push("")

output:Push("local uBenchmarks, iBenchmarks, fBenchmarks = {}, {}, {}")

local function benchmarkNumber(numberType: "u" | "i" | "f", width: number)
	output:Push("do")

	local times = {}
	for _, mode in { "read", "write" } do
		local callbackName = `{mode}{numberType}{width}`
		local startVariable, endVariable = `{callbackName}StartTime`, `{callbackName}EndTime`

		output:Push(`\tlocal {startVariable} = os.clock()`)

		output:Push(`\tfor _ = 1, TEST_COUNT do`)
		output:Push("\t\tfor offset = 0, 7 do")
		output:Push(`\t\t\tbitbuffer.{callbackName}(TEST_BUFFER, 0, offset{if mode == "write" then ", 0" else ""})`)
		output:Push("\t\tend")
		output:Push("\tend")

		output:Push(`\tlocal {endVariable} = os.clock()`)
		output:Push("")

		times[mode] = `( {endVariable} - {startVariable} ) / 8 / TEST_COUNT`
	end

	output:Push(`\ttable.insert({numberType}Benchmarks, \{ "{width}", {times.read}, {times.write} \})`)
	output:Push(`\tprint("Benchmarked {numberType}{width}")`)
	output:Push("\ttask.wait(0.1)")
	output:Push("end\n")
end

for width = 1, 53 do
	benchmarkNumber("u", width)
end

for width = 2, 52 do
	benchmarkNumber("i", width)
end

for _, width in { 16, 32, 64 } do
	benchmarkNumber("f", width)
end

output:Push([[
	
local function formatTime(t: number): string
	return string.format("%.4f", t * 1e9)
end

local function outputReadWriteTable(tableName, data)
	local output = {}

	local maxName, maxReadTime, maxWriteTime = 0, 0, 0
	local formattedData = {}

	for index, value in data do
		local name, readTime, writeTime = value[1], formatTime(value[2]), formatTime(value[3])
		formattedData[index] = { name = name, readTime = readTime, writeTime = writeTime }
		
		maxName = math.max(#name, maxName)
		maxReadTime = math.max(#readTime, maxReadTime)
		maxWriteTime = math.max(#writeTime, maxWriteTime)
	end

	table.insert(output, `┌{string.rep("─", maxName + 2)}┬{string.rep("─", maxReadTime + 2)}┬{string.rep("─", maxWriteTime + 2)}┐`)
	table.insert(output, `│ {tableName}{string.rep(" ", maxName - #tableName)} │ read{string.rep(" ", maxReadTime - 4)} │ write{string.rep(" ", maxWriteTime - 5)} │`)
	table.insert(output, `├{string.rep("─", maxName + 2)}┼{string.rep("─", maxReadTime + 2)}┼{string.rep("─", maxWriteTime + 2)}┤`)

	for _, benchmarkData in formattedData do
		local name, readTime, writeTime = benchmarkData.name, benchmarkData.readTime, benchmarkData.writeTime
		
		local namePadding = string.rep(" ", maxName - #name)
		local readPadding = string.rep(" ", maxReadTime - #readTime)
		local writePadding = string.rep(" ", maxWriteTime - #writeTime)

		table.insert(output, `│ {name}{namePadding} │ {readTime}{readPadding} │ {writeTime}{writePadding} │`)
	end

	table.insert(output, `└{string.rep("─", maxName + 2)}┴{string.rep("─", maxReadTime + 2)}┴{string.rep("─", maxWriteTime + 2)}┘`)
	return output
end

local uint = outputReadWriteTable("u", uBenchmarks)
local int = outputReadWriteTable("i", iBenchmarks)
local float = outputReadWriteTable("f", fBenchmarks)

for index, value in int do
	uint[index] ..= " " .. value
end

for index, value in float do
	uint[index] ..= " " .. value
end

print("\n" .. table.concat(uint, "\n"))]])

local luauSource = tostring(output):gsub("\n%s+\n", "\n\n")
fs.writeFile("./lune/benchmark.luau", luauSource)