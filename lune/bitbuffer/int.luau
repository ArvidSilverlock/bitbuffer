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

		local comment = `Reads a {width} bit signed integer [{-b}, {b - 1}]`
		if width == 53 then
			comment ..= "\n(note this format doesn't match two's complement)"
		end

		luau:Push(`--- {comment:gsub("\n", "\n--- ")}`)
			:BlockStart(`function bitbuffer.readi{width}(b: buffer, byte: number, bit: number): number`)

		if width < 53 then
			local alignedCallback = BUILT_IN_READ[width]
			local unalignedCallback = `( bitbuffer.readu{width}(b, byte, bit) + {b} ) % {a} - {b}`

			if alignedCallback then
				-- stylua: ignore
				luau:Push("return if bit > 0")
					:Push(`\tthen {unalignedCallback}`)
					:Push(`\telse {alignedCallback}(b, byte)`)
			else
				luau:Push(`return {unalignedCallback}`)
			end
		else
			luau:Push(`return bitbuffer.readu53(b, byte, bit) - {b}`)
		end

		luau:BlockEnd():ConditionalPush(width < 53, "")

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

		local comment = `Writes a {width} bit signed integer [{-b}, {b - 1}]`
		if width == 53 then
			comment ..= "\n(note this format doesn't match two's complement)"
		end

		luau:Push(`--- {comment:gsub("\n", "\n--- ")}`)
			:BlockStart(`function bitbuffer.writei{width}(b: buffer, byte: number, bit: number, value: number)`)

		if width < 53 then
			local alignedCallback = BUILT_IN_WRITE[width]
			local unalignedCallback = `bitbuffer.writeu{width}(b, byte, bit, (value + {a}) % {a})`

			if alignedCallback then
				luau:BlockStart("if bit > 0 then")
					:Push(unalignedCallback)
					:BlockMiddle("else")
					:Push(`{alignedCallback}(b, byte, value)`)
					:BlockEnd()
			else
				luau:Push(unalignedCallback)
			end
		else
			luau:Push(`bitbuffer.writeu53(b, byte, bit, value + {b})`)
		end

		luau:BlockEnd():ConditionalPush(width < 53, "")

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

	luau:Push(`bitbuffer.readi = \{ {table.concat(readLookup, ", ")} }`)
		:Push(`bitbuffer.writei = \{ {table.concat(writeLookup, ", ")} }`)

	-- stylua: ignore
	typescript:Push("readi: Array<read<number>>")
		:Push("writei: Array<write<number>>")
		:Push("")
end

return function(luau, typescript)
	-- stylua: ignore
	luau:Block("write", generateWrite, typescript)
		:Block("read", generateRead, typescript)
		:Call(finalise, typescript)
end
