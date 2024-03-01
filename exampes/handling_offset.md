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

This is my personal favourite, balances speed with maintainability, downside is you have to manually specify the `increment` function, otherwise you have to do `byte, bit = increment(byte, bit, n)`, not too nice.
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
local function pushIncrement(output, width)
	local byte, bit = width // 8, width % 8
	if bit == 0 then
		output:Push("outgoingByte += ", byte) -- quick and easy, the bit offset remains the same
	else
		output:Push(`outgoingBit += {bit}`) -- first we increment the bit
		output:BlockStart(`if outgoingBit > 7 then`) -- if we should go onto the next byte
		output:Push(`outgoingByte += {byte + 1}`) -- increment the outgoing byte 1 extra than we would if we didn't go onto the next byte
		output:Push(if bit == 1 then "outgoingBit = 0" else "outgoingBit -= 8") -- effectively do `%= 8`, but only for values 8-15
		
		if byte > 0 then
			output:BlockMiddle("else")
			output:Push(`outgoingByte += {byte}`) -- we only need to increment the byte if it's > 0 by default
		end

		output:BlockEnd()
	end
end
```