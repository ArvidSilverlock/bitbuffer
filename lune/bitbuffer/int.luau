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
	for width = 1, 52 do
		local a, b = 2 ^ width, 2 ^ (width - 1)

		local comment = `Reads a {width} bit signed integer [{-b}, {b - 1}]`

		luau:Push(`--- {comment}`)
			:BlockStart(`function bitbuffer.readi{width}(b: buffer, byte: number, bit: number): number`)

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

		luau:BlockEnd():ConditionalPush(width < 52, "")

		typescript:Push(`/** {comment} */`):Push(`readi{width}: read<number>;`)
	end
end

local function generateWrite(luau, typescript)
	for width = 1, 52 do
		local a, b = 2 ^ width, 2 ^ (width - 1)

		local comment = `Writes a {width} bit signed integer [{-b}, {b - 1}]`

		luau:Push(`--- {comment}`)
			:BlockStart(`function bitbuffer.writei{width}(b: buffer, byte: number, bit: number, value: number)`)

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

		luau:BlockEnd():ConditionalPush(width < 52, "")

		-- stylua: ignore
		typescript:Push(`/** {comment} */`)
			:Push(`writei{width}: write<number>;`)
	end

	typescript:Push("")
end

local function finalise(luau, typescript)
	local readLookup, writeLookup = {}, {}
	for width = 1, 52 do
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

local function create(luau, typescript)
	-- stylua: ignore
	luau:Block("write", generateWrite, typescript)
		:Block("read", generateRead, typescript)
		:Call(finalise, typescript)
end

return create
