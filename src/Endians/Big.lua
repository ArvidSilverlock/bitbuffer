--!foobar_native
--!optimize 2

local U24_BUFFER = buffer.create(4)
local U24_BITS = 24

local function toBufferSpace(offset: number, width: number)
	local byte, bit = offset // 8, offset % 8
	local byteWidth = math.ceil((bit + width) / 8)
	local bitWidth = byteWidth * 8

	bit = (bitWidth - width) - bit

	return byte, bit, byteWidth, bitWidth
end

local function bitIterate(width: number, bit: number)
	return function(_, position)
		if position > 0 then
			local chunkWidth = math.min(position, U24_BITS)
			return position - chunkWidth, chunkWidth
		end
	end,
		nil,
		width
end

local function flipu16(value)
	return bit32.bor(
		value // 256, -- FF00 -> 00FF
		value % 256 * 256 -- 00FF -> FF00
	)
end

local function flipu24(value)
	return bit32.bor(
		value // 65536, -- FF0000 -> 0000FF
		value % 256 * 65536, -- 0000FF -> FF0000
		bit32.band(value, 0x00FF00) -- 00FF00 -> 00FF00
	)
end

return {
	toBufferSpace = toBufferSpace,
	getShiftValue = function(position: number, width: number, chunkWidth: number)
		return width - position - chunkWidth
	end,
	bitIterate = bitIterate,
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
			return bit32.byteswap(buffer.readu32(b, offset))
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
			buffer.writeu32(b, offset, bit32.byteswap(value))
		end,
	},
}
