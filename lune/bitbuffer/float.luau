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
		local exponentBias = 2 ^ (exponentWidth - 1) - 2

		local comment = `Reads a {componentWidths.name}`

		luau:Push(`--- {comment}`)
			:BlockStart(`function bitbuffer.readf{width}(b: buffer, byte: number, bit: number): number`)

		if width == 32 or width == 64 then
			-- stylua: ignore
			luau:BlockStart("if bit == 0 then")
				:Push(`return buffer.readf{width}(b, byte)`)
				:BlockEnd()
				:Push("")
		end

		if width == 64 then
			luau
				:Push(`local mantissa = bitbuffer.readu{mantissaWidth}(b, byte, bit)`)
				:Push(`local offset = byte * 8 + bit + {mantissaWidth}`)
				:Push(`local exponent = bitbuffer.readu{exponentWidth}(b, offset // 8, offset % 8)`)
				:Push(`offset += {exponentWidth}`)
				:Push("local sign = bitbuffer.readu1(b, offset // 8, offset % 8) == 1\n")
				-- Handle infinity
				:BlockStart("if mantissa == 0 and exponent == ", exponentMax, " then")
				:Push("return if sign then -math.huge else math.huge")
				-- Handle NaN
				:BlockMiddle("elseif mantissa == 1 and exponent == ", exponentMax, " then")
				:Push("return 0 / 0")
				-- Handle 0
				:BlockMiddle("elseif mantissa == 0 and exponent == 0 then")
				:Push("return 0")
				:BlockMiddle("else")
		else
			local infinity = `0b{exponentMax}_{string.rep(0, mantissaWidth)}`
			local nan = `0b{exponentMax}_{string.rep(0, mantissaWidth - 1)}1`
			local zero = `0b{string.rep(0, exponentWidth)}_{string.rep(0, mantissaWidth)}`

			luau
				:Push(`local uintForm = bitbuffer.readu{width}(b, byte, bit)`)
				:Push(`local exponent_mantissa = uintForm % {tohex(2 ^ (width - 1))}`)
				:Push("")
				-- Handle infinity
				:BlockStart(`if exponent_mantissa == {infinity} then`)
				:Push(`return if uintForm // {tohex(2 ^ (width - 1))} == 1 then -math.huge else math.huge`)
				-- Handle NaN
				:BlockMiddle(`elseif exponent_mantissa == {nan} then`)
				:Push("return 0 / 0")
				-- Handle 0
				:BlockMiddle(`elseif exponent_mantissa == {zero} then`)
				:Push("return 0")
				-- Handle everything else
				:BlockMiddle("else")
				:Push(`local mantissa = exponent_mantissa % {tohex(2 ^ mantissaWidth)}`)
				:Push(`local exponent = exponent_mantissa // {tohex(2 ^ mantissaWidth)}`)
				:Push(`local sign = uintForm // {tohex(2 ^ (width - 1))} == 1`)
		end

		luau:Push("mantissa = if exponent == 0")
			:Push(`\tthen mantissa / {tohex(2 ^ mantissaWidth)}`)
			:Push(`\telse mantissa / {tohex(2 ^ (mantissaWidth + 1))} + 0.5\n`)
			:Push(`local value = math.ldexp(mantissa, exponent - {exponentBias})`)
			:Push("return if sign then -value else value")
			:BlockEnd()
			:BlockEnd()
			:ConditionalPush(width < 64, "")

		-- stylua: ignore
		typescript
			:Push(`/** {comment} */`)
			:Push(`readf{width}: read<number>;`)
	end

	typescript:Push("")
end

local function generateWrite(luau, typescript)
	for _, width in { 16, 32, 64 } do
		local floatData = FLOAT_WIDTHS[width]
		local mantissaWidth, exponentWidth = floatData.mantissa, floatData.exponent

		local exponentMax = `0b{string.rep("1", exponentWidth)}`
		local exponentBias = 2 ^ (exponentWidth - 1) - 2
		local signValue = if width == 64 then tohex(2 ^ 31) else tohex(2 ^ (mantissaWidth + exponentWidth))

		local comment = `Writes a {floatData.name}`

		luau:Push(`--- {comment}`)
			:BlockStart(`function bitbuffer.writef{width}(b: buffer, byte: number, bit: number, value: number)`)

		-- Handle byte aligned cases when applicable
		if width == 32 or width == 64 then
			luau:BlockStart("if bit == 0 then")
				:Push(`buffer.writef{width}(b, byte, value)`)
				:Push("return")
				:BlockEnd()
				:Push("")
		end

		-- Set default values, this automatically handles the 0 case
		luau:Push("local mantissa, exponent, sign = 0, 0, 0")

		-- Handle infinity
		if width ~= 64 then
			local maxValue = (2 - 2 ^ -mantissaWidth) * 2 ^ (exponentBias + 1)
			luau:BlockStart(`if math.abs(value) > {maxValue} then`)
		else
			luau:BlockStart("if math.abs(value) >= math.huge then")
		end
		luau:Push(`exponent, sign = {exponentMax}, if value < 0 then {signValue} else 0`)

		-- Handle NaN
		-- stylua: ignore
		luau:BlockMiddle("elseif value ~= value then")
			:Push(`mantissa, exponent, sign = 1, {exponentMax}, {signValue}`)
			-- Handle everything else
			:BlockMiddle("elseif value ~= 0 then")
			:Push("local absValue = math.abs(value)")

		-- Round the value to the nearest epsilon, only for halfs and singles, since
		-- luau numbers are already doubles, so it would just yield the same result
		if width ~= 64 then
			luau:Push(`local interval = math.ldexp(1, math.floor(math.log(absValue, 2)) - {mantissaWidth})`)
				:Push("absValue = math.floor(absValue / interval) * interval")
				:Push("")
		end

		luau:Push("mantissa, exponent = math.frexp(absValue)")
			:Push(`exponent += {exponentBias}`)
			:Push("")
			:Push("mantissa = math.round(if exponent <= 0")
			:Push(`\tthen mantissa * {tohex(2 ^ mantissaWidth)} / math.ldexp(1, math.abs(exponent))`)
			:Push(`\telse mantissa * {tohex(2 ^ (mantissaWidth + 1))})`)
			:Push("exponent = math.max(exponent, 0)")
			:Push(`sign = if value < 0 then {signValue} else 0`)
			:BlockEnd()
			:Push("")

		-- If we can utilise a single write call, do so
		if width ~= 64 then
			local hexExponent = tohex(2 ^ mantissaWidth)
			luau:Push("bitbuffer.writeu", width, "(b, byte, bit, mantissa % ", hexExponent)
				:Push("\t+ exponent * ", hexExponent)
				:Push("\t+ sign)")
		else
			luau:Push("bitbuffer.writeu32(b, byte, bit, mantissa % ", tohex(2 ^ 32), ")")
				:Push("bitbuffer.writeu32(b, byte + 4, bit, mantissa // ", tohex(2 ^ 32), " % ", tohex(2 ^ 20))
				:Push("\t+ exponent * ", tohex(2 ^ 20))
				:Push("\t+ sign)")
		end

		luau:BlockEnd()

		-- stylua: ignore
		typescript
			:Push(`/** {comment} */`)
			:Push(`writef{width}: write<number>;`)
	end

	typescript:Push("")
end

local function create(luau, typescript)
	-- stylua: ignore
	luau
		:Block("write", generateWrite, typescript)
		:Block("read", generateRead, typescript)
end

return create
