local bitbuffer = script.Parent.Parent
local toBufferSpace = require(bitbuffer.ToBufferSpace)
local bitIterate = require(bitbuffer.BitIterate)

local U24_BUFFER = buffer.create(4)

local function flipu16(value)
	return bit32.bor(
		bit32.lshift(value, 8), -- FF00 -> 00FF
		bit32.rshift(value, 8) -- 00FF -> FF00
	)
end

local function flipu24(value)
	return bit32.bor(
		bit32.rshift(bit32.band(value, 0xFF0000), 16), -- FF0000 -> 0000FF
		bit32.lshift(bit32.band(value, 0x0000FF), 16), -- 0000FF -> FF0000
		bit32.band(value, 0x00FF00) -- 00FF00 -> 00FF00
	)
end

local function flipu32(value)
	return bit32.bor(
		bit32.rshift(bit32.band(value, 0xFF000000), 24), -- FF000000 -> 000000FF
		bit32.rshift(bit32.band(value, 0x00FF0000), 8), -- 00FF0000 -> 0000FF00
		bit32.lshift(bit32.band(value, 0x0000FF00), 8), -- 0000FF00 -> 00FF0000
		bit32.lshift(bit32.band(value, 0x000000FF), 24) -- 000000FF -> FF000000
	)
end

return {
	toBufferSpace = function(offset: number, width: number)
		local byte, bit, byteWidth = toBufferSpace(offset, width)
		bit = (bit32.lshift(byteWidth, 3) - width) - bit
		return byte, bit, byteWidth
	end,
	getShiftValue = function(position: number, width: number, chunkWidth: number)
		return width - position - chunkWidth
	end,
	bitIterate = bitIterate.flipped,
	read = {
		[1] = buffer.readu8,
		[2] = function(b: buffer, offset: number)
			return flipu16(buffer.readu16(b, offset))
		end,
		[3] = function(b: buffer, offset: number)
			buffer.copy(U24_BUFFER, 0, b, offset, 3)
			return flipu24(buffer.readu32(U24_BUFFER, 0))
		end,
		[4] = function(b: buffer, offset: number)
			return flipu32(buffer.readu32(b, offset))
		end,
	},
	write = {
		[1] = buffer.writeu8,
		[2] = function(b: buffer, offset: number, value: number)
			buffer.writeu16(b, offset, flipu16(value))
		end,
		[3] = function(b: buffer, offset: number, value: number)
			buffer.writeu32(U24_BUFFER, 0, flipu24(value))
			buffer.copy(b, offset, U24_BUFFER, 0, 3)
		end,
		[4] = function(b: buffer, offset: number, value: number)
			buffer.writeu32(b, offset, flipu32(value))
		end,
	},
}
