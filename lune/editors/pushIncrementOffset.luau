local function pushIncrementOffset(luau, offset)
	local byte, bit = offset // 8, offset % 8
	if bit == 0 then
		luau:Push(`self.byte += {byte}`) -- quick and easy, the bit offset remains the same
	else
		luau:Push(
			`self.bit += {bit}`, -- first we increment the bit
			"if self.bit > 7 then", -- if we've gone onto the next byte
			`\tself.byte += {byte + 1}`, -- increment the outgoing byte 1 extra than normal
			if bit == 1
				then "\tself.bit = 0" -- `bit` has to be `8`, so we can just set it to 0
				else "\tself.bit -= 8", -- effectively do `bit %= 8`
			if byte > 0
				then `else\n\tself.byte += {byte}` -- only increment the byte if need be
				else nil,
			"end"
		)
	end
end

return pushIncrementOffset
