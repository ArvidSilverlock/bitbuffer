local Snippet = require("../Snippet.luau")

local READ_TEMPALTE = [[if offset % 8 == 0 then
	return buffer.readf<WIDTH>(b, offset // 8)
end

local mantissa = bitbuffer.readu<MANTISSA_WIDTH>(b, offset)
local exponent = bitbuffer.readu<EXPONENT_WIDTH>(b, offset + <MANTISSA_WIDTH>)
local sign = bitbuffer.readu1(b, offset + <MANTISSA_EXPONENT_WIDTH>) == 1

if mantissa == 0 and exponent == <EXPONENT_MAX> then
	return if sign then -math.huge else math.huge
elseif mantissa == 1 and exponent == <EXPONENT_MAX> then
	return 0 / 0
elseif mantissa == 0 and exponent == 0 then
	return 0
else
	mantissa = if exponent == 0
		then mantissa / <SUBNORMAL>
		else mantissa / <NORMAL> + 0.5

	local value = math.ldexp(mantissa, exponent - <EXPONENT_BIAS>)
	return if sign then -value else value
end]]

local WRITE_TEMPLATE = [[if offset % 8 == 0 then
	buffer.writef<WIDTH>(b, offset // 8, value)
	return
end

local mantissa, exponent, sign = 0, 0, 0
if math.abs(value) > <MAX_VALUE> then
	exponent, sign = <EXPONENT_MAX>, if value < 0 then 1 else 0
elseif value ~= value then
	mantissa, exponent, sign = 1, <EXPONENT_MAX>, 1
elseif value ~= 0 then
	mantissa, exponent = math.frexp(value)
	exponent += <EXPONENT_BIAS>

	mantissa = math.round(if exponent <= 0
		then math.abs(mantissa) * <SUBNORMAL> / math.ldexp(1, math.abs(exponent))
		else math.abs(mantissa) * <NORMAL>)
	exponent = math.max(exponent, 0)
	sign = if value < 0 then 1 else 0
end

bitbuffer.writeu<MANTISSA_WIDTH>(b, offset, mantissa)
bitbuffer.writeu<EXPONENT_WIDTH>(b, offset + <MANTISSA_WIDTH>, exponent)
bitbuffer.writeu1(b, offset + <MANTISSA_EXPONENT_WIDTH>, sign)]]

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

		local content = READ_TEMPALTE:gsub("<MANTISSA_WIDTH>", mantissaWidth)
			:gsub("<EXPONENT_WIDTH>", exponentWidth)
			:gsub("<MANTISSA_EXPONENT_WIDTH>", mantissaWidth + exponentWidth)
			:gsub("<EXPONENT_MAX>", `0b{string.rep("1", exponentWidth)}`)
			:gsub("<EXPONENT_BIAS>", 2 ^ (exponentWidth - 1) - 2)
			:gsub("<SUBNORMAL>", tohex(2 ^ mantissaWidth))
			:gsub("<NORMAL>", tohex(2 ^ (mantissaWidth + 1)))
			:gsub("<WIDTH>", width)

		body:Push("--- Reads a ", componentWidths.name)
		body:Push("function bitbuffer.readf", width, "(b: buffer, offset: number): number")
		body:Push(content):Indent()
		body:Push("end")

		table.insert(output, tostring(body))
	end
	return output
end

local function generateWrite()
	local output = {}
	for _, width in { 16, 32, 64 } do
		local componentWidths = FLOAT_WIDTHS[width]
		local mantissaWidth, exponentWidth = componentWidths.mantissa, componentWidths.exponent

		local body = Snippet.new()

		local content = WRITE_TEMPLATE
			:gsub("<MAX_VALUE>", math.ldexp((2 - 2 ^ -mantissaWidth), (2 ^ (exponentWidth - 1) - 1)))
			:gsub("<MANTISSA_WIDTH>", mantissaWidth)
			:gsub("<EXPONENT_WIDTH>", exponentWidth)
			:gsub("<MANTISSA_EXPONENT_WIDTH>", mantissaWidth + exponentWidth)
			:gsub("<EXPONENT_MAX>", `0b{string.rep("1", exponentWidth)}`)
			:gsub("<EXPONENT_BIAS>", 2 ^ (exponentWidth - 1) - 2)
			:gsub("<SUBNORMAL>", tohex(2 ^ mantissaWidth))
			:gsub("<NORMAL>", tohex(2 ^ (mantissaWidth + 1)))
			:gsub("<WIDTH>", width)

		body:Push("--- Writes a ", componentWidths.name)
		body:Push("function bitbuffer.writef", width, "(b: buffer, offset: number, value: number)")
		body:Push(content):Indent()
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
