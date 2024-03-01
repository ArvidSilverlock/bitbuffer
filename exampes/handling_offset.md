## Combined Offset

One of the simplest, fairly clean, easy to maintain. Lots of excess division though.
```lua
local offset = 0

bitbuffer.writeu12(b, offset // 8, offset % 8, rng:NextNumber(0, 4095))
offset += 12

bitbuffer.writeu32(b, offset // 8, offset % 8, rng:NextNumber(0, 4294967295))
offset += 32
```

## `Reader` and `Writer` classes (OOP)

This one is "slow", yet easy to use and maintain. Not everyone likes OOP though.
```lua
local writer = bitbuffer.writer(b)

writer:UInt12(rng:NextNumber(0, 4095))
writer:UInt32(rng:NextNumber(0, 4294967295))
```

## `Offset` class (OOP)

Still uses OOP, personally not a huge fan of this one.
```lua
local offset = bitbuffer.offset()

bitbuffer.writeu12(b, offset.byte, offset.bit, rng:NextNumber(0, 4095))
offset:IncrementOffset(12)

bitbuffer.writeu32(b, offset.byte, offset.bit, rng:NextNumber(0, 4294967295))
offset:IncrementOffset(32)
```

## Increment Offset Function

This is my personal favourite, balances speed with maintainability. Luau likely even inlines it and optimizes out the `// 8` and `% 8` to make it the same as the one specified below this, if so, this would be, hands down, the best.

Downside is you have to manually specify the `increment` function, otherwise you have to do `byte, bit = increment(byte, bit, n)`, not too nice.
```lua
local byte, bit = 0, 0
local function incrementOffset(offset: number)
    local offsetByte, offsetBit = offset // 8, offset % 8

    bit += offsetBit
    if bit > 7 then
        byte += offsetByte + 1
        bit -= 8
    else
        byte += offsetByte
    end
end

bitbuffer.writeu12(b, byte, bit, rng:NextNumber(0, 4095))
incrementOffset(12)

bitbuffer.writeu32(b, byte, bit, rng:NextNumber(0, 4294967295))
incrementOffset(32)
```

## Automatic Generation

This is the one I consider to be the fastest, due to the lack of division, but the only way to use this method in a maintainable manner (in my opinion) is for automatically generated code (i.e., and IDL language).
```lua
local byte, bit = 0, 0

bitbuffer.writeu12(b, byte, bit, rng:NextNumber(0, 4095))
bit += 4
if bit > 7 then
    byte += 2
    bit -= 8
else
    byte += 1
end

bitbuffer.writeu32(b, byte, bit, rng:NextNumber(0, 4294967295))
byte += 4
```

The above offset was generated using this function:
```lua
local function generateIncrement(width: number): string
	local byte, bit = width // 8, width % 8
	if bit == 0 then
		return `byte += {byte}` -- quick and easy, the bit offset remains the same
	else
		return table.concat({
			`bit += {bit}`, -- first we increment the bit
			"if bit > 7 then", -- if we've gone onto the next byte
			`\tbyte += {byte + 1}`, -- increment the outgoing byte 1 extra than normal
			if bit == 1
				then "\tbit = 0" -- `bit` has to be `8`, so we can just set it to 0
				else "\tbit -= 8", -- effectively do `bit %= 8`
			if byte > 0
				then `else\n\tbyte += {byte}` -- only increment the byte if need be
				else nil,
			"end"
		}, "\n")
	end
end
```