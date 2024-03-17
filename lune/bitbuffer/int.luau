local Snippet = require("../Snippet.luau")

local BUILT_IN_READ = {
	[8] = "readi8",
	[16] = "readi16",
	[32] = "readi32",
}

local BUILT_IN_WRITE = {
	[8] = "writei8",
	[16] = "writei16",
	[32] = "writei32",
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

			-- merely a formatting function
			local function writeCallback(prefix: string, callback: string)
				if #callback:split("\n") > 1 then
					-- stylua: ignore
					luau:Push(
						`{prefix} (`, 1,
							"(", 1,
							callback,
							-1, `) + {hexB}`, -1,
						`) % {hexA} - {hexB}`
					)
				else
					luau:Push(`{prefix} ( {callback} + {hexB} ) % {hexA} - {hexB}`)
				end
			end

			if alignedCallback then
				local unalignedCallback = tostring(Snippet.get(`unalignedreadu{width}`))
				luau:Push("return if bit > 0", 1)
				writeCallback("then", unalignedCallback)
				luau:Push(`else {alignedCallback}(b, byte)`, -1)
			else
				local callback = tostring(Snippet.get(`readu{width}`))
				writeCallback("return", callback)
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

	typescript:Break()
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

		-- this adds the necessary offset, it'll try to avoid doing `+=` if it can
		local function getCallback(name: string)
			local callback = tostring(Snippet.get(name))
			local _, valueCount = callback:gsub("value", "value")

			-- the real formula for 2's compliment is `( value + 2^n ) % 2^n`, but the overflow gets cut off upon writing,
			-- meaning we can omit the modulo for an extra nanosecond of speed!

			-- stylua: ignore
			return if valueCount == 1
				then callback:gsub("value", `value + {hexA}`)
				else `value += {hexA}\n{callback}`
		end

		if width == 53 then
			local callback = Snippet.get("writeu53")
			luau:Push(`value += {string.format("0x%x", 2 ^ 52)}`, callback)
		elseif alignedCallback then
			local unalignedCallback = getCallback(`unalignedwriteu{width}`)

			-- stylua: ignore
			luau:Push(
				"if bit > 0 then", 1,
					unalignedCallback,
				-1, "else", 1,
					`{alignedCallback}(b, byte, value)`,
				-1, "end"
			)
		else
			luau:Push(getCallback(`writeu{width}`))
		end

		luau:Push(-1, "end"):ConditionalPush(width < 53, "")

		-- stylua: ignore
		typescript
			:Push(`/** {comment:gsub("\n", "\n    ")} */`)
			:Push(`writei{width}: write<number>;`)
	end

	typescript:Break()
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
