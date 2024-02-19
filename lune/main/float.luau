local Snippet = require("../Snippet.luau")

local FLOAT_WIDTHS = {
	[16] = { mantissa = 10, exponent = 5, name = "Half-precision IEEE 754 number" },
	[32] = { mantissa = 23, exponent = 8, name = "Single-precision IEEE 754 number" },
	[64] = { mantissa = 52, exponent = 11, name = "Double-precision IEEE 754 number" },
}

local function tohex(value: number): string
	return string.format("0x%x", value)
end

local function generateRead()
	local output = {}
	for _, width in { 16, 32, 64 } do
		local componentWidths = FLOAT_WIDTHS[width]
		local mantissaWidth, exponentWidth = componentWidths.mantissa, componentWidths.exponent

		local body = Snippet.new()

		local exponentMax = `0b{string.rep("1", exponentWidth)}`
		local exponentBias = 2 ^ (exponentWidth - 1) - 2

		if width == 32 or width == 64 then
			body:Push("\tif offset % 8 == 0 then")
			body:Push("\t\treturn buffer.readf", width, "(b, offset // 8)")
			body:Push("\tend\n")
		end

		-- Read each component
		body:Push("local mantissa = bitbuffer.readu", mantissaWidth, "(b, offset)")
		body:Push("local exponent = bitbuffer.readu", exponentWidth, "(b, offset + ", mantissaWidth, ")")
		body:Push("local sign = bitbuffer.readu1(b, offset + ", mantissaWidth + exponentWidth, ") == 1\n")

		-- Handle infinity
		body:Push("if mantissa == 0 and exponent == ", exponentMax, " then")
		body:Push("\treturn if sign then -math.huge else math.huge")

		-- Handle NaN
		body:Push("elseif mantissa == 1 and exponent == ", exponentMax, " then")
		body:Push("\treturn 0 / 0")

		-- Handle 0
		body:Push("elseif mantissa == 0 and exponent == 0 then")
		body:Push("\treturn 0")

		-- Handle everything else
		body:Push("else")
		body:Push("\tmantissa = if exponent == 0")
		body:Push("\t\tthen mantissa / ", tohex(2 ^ mantissaWidth))
		body:Push("\t\telse mantissa / ", tohex(2 ^ (mantissaWidth + 1)), " + 0.5\n")

		body:Push("\tlocal value = math.ldexp(mantissa, exponent - ", exponentBias, ")")
		body:Push("	return if sign then -value else value")
		body:Push("end")

		body:Indent()

		body:Insert(1, "--- Reads a ", componentWidths.name)
		body:Insert(2, "function bitbuffer.readf", width, "(b: buffer, offset: number): number")

		body:Push("end")

		table.insert(output, tostring(body))
	end
	return output
end

local function generateWrite()
	local output = {}
	for _, width in { 16, 32, 64 } do
		local floatData = FLOAT_WIDTHS[width]
		local mantissaWidth, exponentWidth = floatData.mantissa, floatData.exponent

		local body = Snippet.new()

		local exponentMax = `0b{string.rep("1", exponentWidth)}`
		local exponentBias = 2 ^ (exponentWidth - 1) - 2

		-- Handle byte aligned cases when applicable
		if width == 32 or width == 64 then
			body:Push("if offset % 8 == 0 then")
			body:Push("\tbuffer.writef", width, "(b, offset // 8, value)")
			body:Push("\treturn")
			body:Push("end\n")
		end

		-- Set default values, this automatically handles the 0 case
		body:Push("local mantissa, exponent, sign = 0, 0, 0")

		-- Handle infinity
		if width ~= 64 then
			local maxValue = (2 - 2 ^ -mantissaWidth) * 2 ^ (exponentBias + 1)
			body:Push("if math.abs(value) > ", maxValue, " then")
		else
			body:Push("if math.abs(value) >= math.huge then")
		end
		body:Push("\texponent, sign = ", exponentMax, ", if value < 0 then 1 else 0")

		-- Handle NaN
		body:Push("elseif value ~= value then")
		body:Push("\tmantissa, exponent, sign = 1, ", exponentMax, ", 1")

		-- Handle everything else
		body:Push("elseif value ~= 0 then")
		body:Push("\tlocal absValue = math.abs(value)")

		-- Round the value to the nearest epsilon, only for halfs and singles, since
		-- luau numbers are already doubles, so it would just yield the same result
		if width ~= 64 then
			local min = "math.floor(math.log(absValue, 2))"
			body:Push("\tlocal interval = math.ldexp(1, ", min, " - ", mantissaWidth, ")")
			body:Push("\tabsValue = math.floor(absValue / interval) * interval\n")
		end

		body:Push("\tmantissa, exponent = math.frexp(absValue)")
		body:Push("\texponent += ", exponentBias, "\n")
		body:Push("\tmantissa = math.round(if exponent <= 0")
		body:Push("\t\tthen mantissa * ", tohex(2 ^ mantissaWidth), " / math.ldexp(1, math.abs(exponent))")
		body:Push("\t\telse mantissa * ", tohex(2 ^ (mantissaWidth + 1)), ")")
		body:Push("\texponent = math.max(exponent, 0)")
		body:Push("\tsign = if value < 0 then 1 else 0")
		body:Push("end\n")

		-- Write the values to the buffer
		body:Push("bitbuffer.writeu", mantissaWidth, "(b, offset, mantissa)")
		body:Push("bitbuffer.writeu", exponentWidth, "(b, offset + ", mantissaWidth, ", exponent)")
		body:Push("bitbuffer.writeu1(b, offset + ", mantissaWidth + exponentWidth, ", sign)")

		body:Indent()

		body:Insert(1, "--- Writes a ", floatData.name)
		body:Insert(2, "function bitbuffer.writef", width, "(b: buffer, offset: number, value: number)")

		body:Push("end")

		table.insert(output, tostring(body))
	end
	return output
end

local function create(addSection)
	local output = {}

	addSection("write", generateWrite, output)
	addSection("read", generateRead, output)

	return output
end

return create
