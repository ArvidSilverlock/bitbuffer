local U24_BITS = 24
local U32_BITS = 32

local function littleEndian(width: number, bit: number)
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

local function bigEndian(width: number, bit: number)
	return function(_, position)
		if position > 0 then
			local chunkWidth = math.min(position, U24_BITS)
			return position - chunkWidth, chunkWidth
		end
	end,
		nil,
		width
end

return {
	littleEndian = littleEndian,
	bigEndian = bigEndian,
}
