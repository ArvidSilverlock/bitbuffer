local function toBufferSpace(offset: number, width: number)
	local byte, bit = bit32.rshift(offset, 3), bit32.band(offset, 0b111) -- offset * 8, offset % 8
	local byteWidth = bit32.rshift(bit + width + 7, 3) -- math.ceil(( bit + width ) / 8)
	return byte, bit, byteWidth
end

return toBufferSpace
