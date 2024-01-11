local bitbuffer = script.Parent.Parent
local toBufferSpace = require(bitbuffer.ToBufferSpace)
local bitIterate = require(bitbuffer.BitIterate)

local U24_BUFFER = buffer.create(4)

return {
	toBufferSpace = toBufferSpace,
	getShiftValue = function(position: number, width: number, chunkWidth: number)
		return position
	end,
	bitIterate = bitIterate.normal,
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
