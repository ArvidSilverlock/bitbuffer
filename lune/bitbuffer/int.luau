local Snippet = require("../Snippet.luau")

local BUILT_IN_READ = {
	[8] = "buffer.readi8",
	[16] = "buffer.readi16",
	[32] = "buffer.readi32",
}

local BUILT_IN_WRITE = {
	[8] = "buffer.writei8",
	[16] = "buffer.writei16",
	[32] = "buffer.writei32",
}

local function generateRead(luau, typescript)
	for width = 1, 53 do
		local a, b = 2 ^ width, 2 ^ (width - 1)
		local hexA, hexB = string.format("0x%x", a), string.format("0x%x", b)

		local comment = `Reads a {width} bit signed integer [{-b}, {b - 1}]`
		if width == 53 then
			comment ..= "\n(note this format doesn't match two's complement)"
		end

		-- stylua: ignore
		luau:Push(
			`--- {comment:gsub("\n", "\n--- ")}`,
			`function bitbuffer.readi{width}(b: buffer, byte: number, bit: number): number`, 1
		)

		if width < 53 then
			local alignedCallback = BUILT_IN_READ[width]
			local unalignedCallback = tostring(Snippet.get(`readu{width}`))

			if alignedCallback then
				-- stylua: ignore
				luau:Push(
					"return if bit > 0", 1,
						"then (", 1,
							"(", 1,
								unalignedCallback,
							-1, `) + {hexB}`, -1,
						`) % {hexA} - {hexB}`,
						`else {alignedCallback}(b, byte)`, -1
				)
			else
				if unalignedCallback:match("^if ") then
					-- stylua: ignore
					luau:Push(
						"return (", 1,
							"(", 1,
								unalignedCallback,
							-1, `) + {hexB}`, -1,
						`) % {hexA} - {hexB}`
					)
				else
					-- stylua: ignore
					luau:Push(
						`return ( {unalignedCallback} + {hexB} ) % {hexA} - {hexB}`
					)
				end
			end
		else
			luau:Push(`return bitbuffer.readu53(b, byte, bit) - {b}`)
		end

		luau:Push(-1, "end"):ConditionalPush(width < 53, "")

		-- stylua: ignore
		typescript
			:Push(`/** {comment} */`)
			:Push(`readi{width}: read<number>;`)
	end

	typescript:Push("")
end

local function generateWrite(luau, typescript)
	for width = 1, 53 do
		local a, b = 2 ^ width, 2 ^ (width - 1)
		local hexA = string.format("0x%x", a)

		local comment = `Writes a {width} bit signed integer [{-b}, {b - 1}]`
		if width == 53 then
			comment ..= "\n(note this format doesn't match two's complement)"
		end

		-- stylua: ignore
		luau:Push(
			`--- {comment:gsub("\n", "\n--- ")}`,
			`function bitbuffer.writei{width}(b: buffer, byte: number, bit: number, value: number)`, 1
		)

		local alignedCallback = BUILT_IN_WRITE[width]
		local unalignedCallback = Snippet.get(`writeu{width}`)
		local convertToUInt = `value = ( value + {hexA} ) % {hexA}`

		if width == 53 then
			luau:Push(`value += {string.format("0x%x", 2 ^ 52)}`, unalignedCallback)
		elseif alignedCallback then
				-- stylua: ignore
				luau:Push(
					"if bit > 0 then", 1,
						convertToUInt,
						unalignedCallback,
					-1, "else", 1,
						`{alignedCallback}(b, byte, value)`,
					-1, "end"
				)
		else
				-- stylua: ignore
				luau:Push(
					convertToUInt,
					unalignedCallback
				)
		end

		luau:Push(-1, "end"):ConditionalPush(width < 53, "")

		-- stylua: ignore
		typescript
			:Push(`/** {comment:gsub("\n", "\n    ")} */`)
			:Push(`writei{width}: write<number>;`)
	end

	typescript:Push("")
end

local function finalise(luau, typescript)
	local readLookup, writeLookup = {}, {}
	for width = 1, 53 do
		table.insert(readLookup, `bitbuffer.readi{width}`)
		table.insert(writeLookup, `bitbuffer.writei{width}`)
	end

	luau:Push(
		`bitbuffer.readi = \{ {table.concat(readLookup, ", ")} }`,
		`bitbuffer.writei = \{ {table.concat(writeLookup, ", ")} }`
	)

	-- stylua: ignore
	typescript:Push(
		"readi: Array<read<number>>",
		"writei: Array<write<number>>",
		""
	)
end

return function(luau, typescript)
	-- stylua: ignore
	luau:LuauBlock("write", generateWrite, typescript)
		:LuauBlock("read", generateRead, typescript)
		:Call(finalise, typescript)
end
