--!native
--!optimize 2

local U24_BUFFER = buffer.create(4)
local U32_BITS = 32

local function toBufferSpace(offset: number, width: number)
	local byte, bit = bit32.rshift(offset, 3), bit32.band(offset, 0b111) -- offset * 8, offset % 8
	local byteWidth = bit32.rshift(bit + width + 7, 3) -- math.ceil(( bit + width ) / 8)
	return byte, bit, byteWidth
end

local function getShiftValue(position: number, width: number, chunkWidth: number)
	return position
end

local function bitIterate(width: number, bit: number)
	local chunkWidth = if bit % 8 == 0 then U32_BITS else 8 - bit
	local position = 0

	return function()
		if chunkWidth > 0 then
			local previousPosition, previousChunkWidth = position, chunkWidth

			position += chunkWidth
			chunkWidth = math.min(width - position, U32_BITS)

			return previousPosition, previousChunkWidth
		end
	end
end

return {
	toBufferSpace = toBufferSpace,
	getShiftValue = getShiftValue,
	bitIterate = bitIterate,
	read = {
		[1] = buffer.readu8,
		[2] = buffer.readu16,
		[3] = function(b: buffer, offset: number)
			buffer.copy(U24_BUFFER, 0, b, offset, 3)
			return buffer.readu32(U24_BUFFER, 0)
		end,
		[4] = buffer.readu32,
	},
	write = {
		[1] = buffer.writeu8,
		[2] = buffer.writeu16,
		[3] = function(b: buffer, offset: number, value: number)
			buffer.writeu32(U24_BUFFER, 0, value)
			buffer.copy(b, offset, U24_BUFFER, 0, 3)
		end,
		[4] = buffer.writeu32,
	},
}
