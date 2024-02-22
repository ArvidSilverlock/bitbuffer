local bitbuffer = require("../src/init.luau")
local b = buffer.create(512)

local function random(min: number, max: number): number
	return math.random() * (max - min) + min
end

local function test(name: string, read, write, round)
	return function(value: number, ...: any)
		local rounded = if round then round(value) else value
		for offset = 0, 7 do
			write(b, offset, rounded, ...)
			local readOutput = read(b, offset, ...)
			if readOutput ~= rounded then
				error(`read/write {name} failed on offset {offset} for the value {rounded} (got {readOutput})`)
			end
		end
	end
end

local function generateString(): (string, number)
	local length = math.random(1, 256)
	local str = buffer.create(length)

	for offset = 0, length - 1 do
		buffer.writeu8(str, offset, math.random(0, 255))
	end

	return buffer.tostring(str), length
end

local output = setmetatable({}, { __index = table })

output:insert("┌────────────┬────┐")

do -- uints and ints
	for width = 1, 53 do
		local testUInt = test(`u{width}`, bitbuffer[`readu{width}`], bitbuffer[`writeu{width}`], math.round)
		local uintMax = 2 ^ width - 1

		if width == 1 or width == 53 then
			for _ = 1, 1024 do
				testUInt(random(0, uintMax))
			end
		else
			local testInt = test(`i{width}`, bitbuffer[`readi{width}`], bitbuffer[`writei{width}`], math.round)
			local intMin = -2 ^ (width - 1)
			local intMax = -intMin - 1

			for _ = 1, 1024 do
				testUInt(random(0, uintMax))
				testInt(random(intMin, intMax))
			end
		end
	end
end
output:insert("│ uints/ints │ ✅ │")

do -- floats
	local testf16 = test("f16", bitbuffer.readf16, bitbuffer.writef16, function(value)
		local interval = 2 ^ (math.floor(math.log(math.abs(value), 2)) - 10)
		return math.floor(value / interval) * interval
	end)

	local testf32 = test("f32", bitbuffer.readf32, bitbuffer.writef32, function(value)
		local interval = 2 ^ (math.floor(math.log(math.abs(value), 2)) - 23)
		return math.floor(value / interval) * interval
	end)

	local testf64 = test("f64", bitbuffer.readf64, bitbuffer.writef64)

	for _ = 1, 1024 do
		local value = random(-1024, 1024)
		testf16(value)
		testf32(value)
		testf64(value)
	end
end
output:insert("│ floats     │ ✅ │")

do -- strings
	local teststring = test("string", bitbuffer.readstring, bitbuffer.writestring)
	for _ = 1, 1024 do
		teststring(generateString())
	end
end
output:insert("│ strings    │ ✅ │")

do -- fill
	for count = 1, 64 do
		for value = 0, 255 do
			for offset = 0, 7 do
				bitbuffer.fill(b, offset, value, count)

				local endOffset = count // 8 * 8
				local overhang = count - endOffset

				for chunkOffset = 0, endOffset - 8, 8 do
					local chunk = bitbuffer.readu8(b, offset + chunkOffset)
					if chunk ~= value then
						error(`{chunk} ~= {value} ({count})`)
					end
				end

				if overhang > 0 then
					local chunk = bitbuffer.readu(b, offset + endOffset, overhang)
					local targetValue = value % 2 ^ overhang

					if chunk ~= targetValue then
						error(`{chunk} ~= {targetValue} ({count})`)
					end
				end
			end
		end
	end
end
output:insert("│ fill       │ ✅ │")

do -- copy
	local source = buffer.create(64)
	for offset = 0, 63 do
		buffer.writeu8(source, offset, math.random(0, 255))
	end

	for count = 1, 504 do
		for sourceOffset = 0, 7 do
			for targetOffset = 0, 7 do
				bitbuffer.copy(b, targetOffset, source, sourceOffset, count)

				local endOffset = count // 8 * 8
				local overhang = count - endOffset

				for chunkOffset = 0, endOffset - 8, 8 do
					local sourceChunk = bitbuffer.readu8(source, sourceOffset + chunkOffset)
					local targetChunk = bitbuffer.readu8(b, targetOffset + chunkOffset)
					if sourceChunk ~= targetChunk then
						error(`{sourceChunk} ~= {targetChunk} ({chunkOffset}, {count})`)
					end
				end

				if overhang > 0 then
					local sourceChunk = bitbuffer.readu(source, sourceOffset + endOffset, overhang)
					local targetChunk = bitbuffer.readu(b, targetOffset + endOffset, overhang)
					if sourceChunk ~= targetChunk then
						error(`{sourceChunk} ~= {targetChunk} (overhang, {endOffset}, {count})`)
					end
				end
			end
		end
	end
end
output:insert("│ copy       │ ✅ │")

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

	for _ = 1, 1024 do
		local str = generateString()
		executeTest(str)
	end
end

do -- bases
	testbase(bitbuffer.tobinary, bitbuffer.frombinary, {})
	output:insert("│ binary     │ ✅ │")

	testbase(bitbuffer.tohexadecimal, bitbuffer.fromhexadecimal, {})
	output:insert("│ hex        │ ✅ │")

	testbase(bitbuffer.tobase64, bitbuffer.frombase64, {
		["The quick brown fox jumps over the lazy dog."] = "VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZy4=",
		["foobar"] = "Zm9vYmFy",
		["glaggle"] = "Z2xhZ2dsZQ==",
		["a"] = "YQ==",
		["ab"] = "YWI=",
	})
	output:insert("│ base64     │ ✅ │")
end

output:insert("└────────────┴────┘")

print(output:concat("\n"))
