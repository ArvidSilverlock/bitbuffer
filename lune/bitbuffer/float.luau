local Snippet = require("../Snippet.luau")

local FLOAT_WIDTHS = {
	[16] = { mantissa = 10, exponent = 5, name = "half-precision IEEE 754 number" },
	[32] = { mantissa = 23, exponent = 8, name = "single-precision IEEE 754 number" },
	[64] = { mantissa = 52, exponent = 11, name = "double-precision IEEE 754 number" },
}

local function tohex(value: number): string
	return string.format("0x%x", value)
end

local function generateRead(luau, typescript)
	for _, width in { 16, 32, 64 } do
		local componentWidths = FLOAT_WIDTHS[width]
		local mantissaWidth, exponentWidth = componentWidths.mantissa, componentWidths.exponent

		local exponentMax = string.rep("1", exponentWidth)
		local exponentMin = string.rep("0", exponentWidth)
		local mantissaMin = string.rep("0", exponentWidth)
		local mantissaOne = string.rep(0, mantissaWidth - 1) .. "1"

		local exponentBias = 2 ^ (exponentWidth - 1) - 2

		local comment = `Reads a {componentWidths.name}`

		-- stylua: ignore
		luau:Push(
			`--- {comment}`,
			`function bitbuffer.readf{width}(b: buffer, byte: number, bit: number): number`, 1
		)

		if width == 32 or width == 64 then
			-- stylua: ignore
			luau:Push("if bit == 0 then", 1,
					`return buffer_readf{width}(b, byte)`,
				-1, "end",
				""
			)
		end

		if width == 64 then
			local readFirst = tostring(Snippet.get("unalignedreadu48"))
			local readSecond = tostring(Snippet.get("unalignedreadu16")):gsub("byte", "byte + 6")

			local sign = `local sign = secondHalf // {tohex(2 ^ 15)} == 1`

			-- stylua: ignore
			luau:Push(
				`local firstHalf = {readFirst}`,
				`local secondHalf = {readSecond}`,
				"",
				`local mantissa = firstHalf`, 1,
					`+ secondHalf % {tohex(2 ^ 4)} * {tohex(2 ^ 48)}`, -1,
				`local exponent = secondHalf // {tohex(2 ^ 4)} % {tohex(2 ^ 11)}`,
				"",
				`if exponent == 0b{exponentMax} and mantissa == 0b{mantissaMin} then`, 1,
					sign,
					"return if sign then -math.huge else math.huge",
				-1, `elseif exponent == 0b{exponentMin} and mantissa == 0b{mantissaOne} then`, 1,
					"return 0 / 0",
				-1, `elseif exponent == 0b{exponentMin} and mantissa == 0b{mantissaMin} then`, 1,
					"return 0",
				-1, "else", 1,
					sign
			)
		else
			local readCallName = if width == 32 then `unalignedreadu{width}` else `readu{width}`
			local readCall = tostring(Snippet.get(readCallName)):gsub("value", "uintForm")

			-- stylua: ignore
			luau:Push(
				`local uintForm = {readCall}`,
				`local exponent_mantissa = uintForm % {tohex(2 ^ (width - 1))}`,
				"",
				`if exponent_mantissa == 0b{exponentMax}_{mantissaMin} then`, 1,
					`return if uintForm // {tohex(2 ^ (width - 1))} == 1 then -math.huge else math.huge`,
				-1, `elseif exponent_mantissa == 0b{exponentMax}_{mantissaOne} then`, 1,
					"return 0 / 0",
				-1, `elseif exponent_mantissa == 0b{exponentMin}_{mantissaMin} then`, 1,
					"return 0",
				-1, "else", 1,
					`local mantissa = exponent_mantissa % {tohex(2 ^ mantissaWidth)}`,
					`local exponent = exponent_mantissa // {tohex(2 ^ mantissaWidth)}`,
					`local sign = uintForm // {tohex(2 ^ (width - 1))} == 1`
			)
		end

		-- stylua: ignore
		luau:Push(
			"mantissa = if exponent == 0", 1,
				`then mantissa / {tohex(2 ^ mantissaWidth)}`,
				`else mantissa / {tohex(2 ^ (mantissaWidth + 1))} + 0.5`, -1,
			"",
			`local value = math.ldexp(mantissa, exponent - {exponentBias})`,
			"return if sign then -value else value",
			-1, "end",
			-1, "end"
		):ConditionalPush(width < 64, "")

		-- stylua: ignore
		typescript:Push(
			`/** {comment} */`,
			`readf{width}: read<number>;`
		)
	end

	typescript:Break()
end

local function generateWrite(luau, typescript)
	for _, width in { 16, 32, 64 } do
		local floatData = FLOAT_WIDTHS[width]
		local mantissaWidth, exponentWidth = floatData.mantissa, floatData.exponent

		local exponentMax = `0b{string.rep("1", exponentWidth)}`
		local exponentBias = 2 ^ (exponentWidth - 1) - 2

		-- float64s write the first 48 bits and the last 16 bits separately, the sign is in the last 16 bits, so it needs to be `2^15`.
		local signValue = if width == 64 then tohex(2 ^ 15) else tohex(2 ^ (width - 1))

		local comment = `Writes a {floatData.name}`

		-- stylua: ignore
		luau:Push(
			`--- {comment}`,
			`function bitbuffer.writef{width}(b: buffer, byte: number, bit: number, value: number)`, 1
		)

		-- Handle byte aligned cases when applicable
		if width == 32 or width == 64 then
			-- stylua: ignore
			luau:Push(
				"if bit == 0 then", 1,
					`writef{width}(b, byte, value)`,
					"return",
				-1, "end",
				""
			)
		end

		-- Set default values, this automatically handles the 0 case
		luau:Push("local mantissa, exponent, sign = 0, 0, 0")

		-- Handle infinity
		if width ~= 64 then
			local maxValue = (2 - 2 ^ -mantissaWidth) * 2 ^ (exponentBias + 1)
			luau:Push(`if math.abs(value) > {maxValue} then`, 1)
		else
			luau:Push("if math.abs(value) >= math.huge then", 1)
		end

		-- stylua: ignore
		luau:Push(
			`exponent, sign = {exponentMax}, if value < 0 then {signValue} else 0`,
			-1, "elseif value ~= value then", 1,
				`mantissa, exponent, sign = 1, {exponentMax}, {signValue}`,
			-1, "elseif value ~= 0 then", 1,
				"local absValue = math.abs(value)"
		)

		-- Round the value to the nearest epsilon, only for halfs and singles, since
		-- luau numbers are already doubles, so it would just yield the same result
		if width ~= 64 then
			luau:Push(`local epsilon = math.ldexp(1, math.floor(math.log(absValue, 2)) - {mantissaWidth})`)
				:Push("absValue = math.floor(absValue / epsilon) * epsilon")
				:Break()
		end

		-- stylua: ignore
		luau:Push(
			"mantissa, exponent = math.frexp(absValue)",
			`exponent += {exponentBias}`,
			"",
			"mantissa = math.round(if exponent <= 0", 1,
				`then mantissa * {tohex(2 ^ mantissaWidth)} / math.ldexp(1, math.abs(exponent))`,
				`else mantissa * {tohex(2 ^ (mantissaWidth + 1))})`, -1,
			"exponent = math.max(exponent, 0)",
			`sign = if value < 0 then {signValue} else 0`,
			-1, "end",
			""
		)

		-- If we can utilise a single write call, do so
		if width < 64 then
			local hexExponent = tohex(2 ^ mantissaWidth)

			local writeCallName = if width == 32 then `unalignedwriteu{width}` else `writeu{width}`
			local writeCall = tostring(Snippet.get(writeCallName)):gsub("value", "uintForm")

			-- stylua: ignore
			luau:Push(
				`local uintForm = mantissa % {hexExponent}`, 1,
					`+ exponent * {hexExponent}`,
					"+ sign", -1,
				"",
				writeCall
			)
		else
			local firstWrite = tostring(Snippet.get("unalignedwriteu48")):gsub("value", "firstHalf")
			local secondWrite = tostring(Snippet.get("unalignedwriteu16")):gsub("value", "secondHalf")

			-- stylua: ignore
			luau:Push(
				`local firstHalf = mantissa % {tohex(2 ^ 48)}`,
				`local secondHalf = mantissa // {tohex(2 ^ 48)} % {tohex(2 ^ 4)}`, 1,
					`+ exponent * {tohex(2 ^ 4)}`,
					"+ sign", -1,
				"",
				firstWrite,
				"byte += 3",
				secondWrite
			)
		end

		luau:Push(-1, "end"):ConditionalPush(width < 64, "")

		-- stylua: ignore
		typescript:Push(
			`/** {comment} */`,
			`writef{width}: write<number>;`
		)
	end

	typescript:Break()
end

return function(luau, typescript)
	-- stylua: ignore
	luau:LuauBlock("write", generateWrite, typescript)
		:Break()
		:LuauBlock("read", generateRead, typescript)
end
