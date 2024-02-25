-- This test will only run properly in a roblox environment, many of the tests are not ran in lune

local EPSILON = 0.01

local function generateSequence(constructor, generateKeypoint)
	return function()
		local length = math.random(2, 20)
		local keypoints = table.create(length)

		keypoints[1] = generateKeypoint(0)
		for index = 2, length - 1 do
			keypoints[index] = generateKeypoint()
		end
		keypoints[length] = generateKeypoint(1)

		table.sort(keypoints, function(a, b)
			return a.Time < b.Time
		end)

		return constructor(keypoints)
	end
end

local function compareSequences(compareKeypoints)
	return function(a, b)
		local keypointsA, keypointsB = a.Keypoints, b.Keypoints
		if #keypointsA ~= #keypointsB then
			return false
		end

		for i = 1, #keypointsA do
			if not compareKeypoints(keypointsA[i], keypointsB[i]) then
				return false
			end
		end

		return true
	end
end

local function fuzzyeq(a, b)
	return a:FuzzyEq(b, EPSILON)
end

local function randomInt16(): number
	return math.random(-32768, 32767)
end

-- Can't use `math.random` as these numbers are too large, `Random` doesn't exist in lune as of 24/2/2024
local function randomInt32(): number
	return math.floor(math.random() * 4294967295)
end

-- Not uniformly distributed
local function randomUnitVector()
	return Vector3.new(math.random(), math.random(), math.random()).Unit
end

local tests = {}

tests.Boolean = {
	generate = function(): boolean
		return math.random() < 0.5
	end,
}

tests.String = {
	generate = function(): string
		local length = math.random(0, 16)
		local str = buffer.create(length)

		for offset = 0, length - 1 do
			buffer.writeu8(str, offset, math.random(0, 255))
		end

		return buffer.tostring(str)
	end,
}

if CFrame then
	local function generate(): CFrame
		local position = randomUnitVector() * 1024
		return CFrame.fromAxisAngle(randomUnitVector(), math.random() * math.pi) + position
	end

	tests.LosslessCFrame = { generate = generate }
	tests.CFrame = {
		generate = generate,
		compare = fuzzyeq,
	}
end

if Color3 then
	local function generateColor3(): Color3
		return Color3.new(math.random(), math.random(), math.random())
	end

	local function compareColor3(a: Color3, b: Color3)
		return (Vector3.new(a.R, a.G, a.B) - Vector3.new(b.R, b.G, b.B)).Magnitude < EPSILON
	end

	tests.Color3 = {
		generate = generateColor3,
		compare = compareColor3,
	}

	if ColorSequenceKeypoint then
		local function generateKeypoint(time: number): ColorSequenceKeypoint
			return ColorSequenceKeypoint.new(time or math.random(), generateColor3())
		end

		local function compareKeypoints(a: ColorSequenceKeypoint, b: ColorSequenceKeypoint)
			return math.abs(a.Time - b.Time) < EPSILON and compareColor3(a.Value, b.Value)
		end

		tests.ColorSequenceKeypoint = {
			generate = generateKeypoint,
			compare = compareKeypoints,
		}

		if ColorSequence then
			tests.ColorSequence = {
				generate = generateSequence(ColorSequence.new, generateKeypoint),
				compare = compareSequences(compareKeypoints),
			}
		end
	end
end

if NumberSequenceKeypoint then
	local function generateKeypoint(time: number): NumberSequenceKeypoint
		return NumberSequenceKeypoint.new(time or math.random(), math.random() * 10)
	end

	local function compareKeypoints(a: NumberSequenceKeypoint, b: NumberSequenceKeypoint)
		return math.abs(a.Time - b.Time) < EPSILON and math.abs(a.Value - b.Value) < EPSILON
	end

	tests.NumberSequenceKeypoint = {
		generate = generateKeypoint,
		compare = compareKeypoints,
	}

	if NumberSequence then
		tests.NumberSequence = {
			generate = generateSequence(NumberSequence.new, generateKeypoint),
			compare = compareSequences(compareKeypoints),
		}
	end
end

if NumberRange then
	tests.NumberRange = {
		generate = function(): NumberRange
			local a, b = math.random() * 10, math.random() * 10
			return NumberRange.new(math.min(a, b), math.max(a, b))
		end,
		compare = function(a: NumberRange, b: NumberRange)
			return math.abs(a.Min - b.Min) < EPSILON and math.abs(a.Max - b.Max) < EPSILON
		end,
	}
end

if Vector3 then
	tests.Vector3 = {
		generate = function(): Vector3
			return Vector3.new(math.random(), math.random(), math.random()) * 256
		end,
		compare = fuzzyeq,
	}
end

if Vector2 then
	tests.Vector2 = {
		generate = function(): Vector2
			return Vector2.new(math.random(), math.random()) * 256
		end,
		compare = fuzzyeq,
	}
end

if Vector3int16 then
	tests.Vector3int16 = {
		generate = function(): Vector3int16
			return Vector3int16.new(randomInt16(), randomInt16(), randomInt16()) * 256
		end,
		compare = function(a, b)
			local difference = a - b
			return math.sqrt(difference.X ^ 2 + difference.Y ^ 2 + difference.Z ^ 2) < EPSILON
		end,
	}
end

if Vector2int16 then
	tests.Vector2int16 = {
		generate = function(): Vector2int16
			return Vector2int16.new(randomInt16(), randomInt16()) * 256
		end,
		compare = function(a, b)
			local difference = a - b
			return math.sqrt(difference.X ^ 2 + difference.Y ^ 2) < EPSILON
		end,
	}
end

if BrickColor then
	tests.BrickColor = {
		generate = BrickColor.random,
	}
end

if UDim then
	local function generateUDim()
		return UDim.new(math.random(), randomInt32())
	end

	local function compareUDim(a, b)
		return math.abs(a.Scale - b.Scale) < EPSILON and a.Offset == b.Offset
	end

	tests.UDim = {
		generate = generateUDim,
		compare = compareUDim,
	}

	if UDim2 then
		tests.UDim2 = {
			generate = function()
				return UDim2.new(generateUDim(), generateUDim())
			end,
			compare = function(a, b)
				return compareUDim(a.X, b.X) and compareUDim(a.Y, b.Y)
			end,
		}
	end
end

if BrickColor then
	tests.BrickColor = {
		generate = BrickColor.random,
	}
end

return function(b, bitbuffer, test, testbase, random, randomString, testCount)
	local reader, writer = bitbuffer.reader(b), bitbuffer.writer(b)

	for name, test in tests do
		local read, write = reader[name], writer[name]

		for _ = 1, testCount do
			local value = test.generate()

			write(writer, value)
			local readValue = read(reader)

			local success = if test.compare then test.compare(value, readValue) else value == readValue
			if not success then
				error(`'{name}' failed to read/write the value '{value}' (got '{readValue}')`)
			end
		end

		reader:SetOffset(0)
		writer:SetOffset(0)
	end
end
