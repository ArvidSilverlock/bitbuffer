local CONSTANTS =
	[[local POWERS_OF_TWO = { [0] = 1, [1] = 2, [2] = 4, [3] = 8, [4] = 16, [5] = 32, [6] = 64, [7] = 128, [8] = 256 }]]

--[[
	There are three cases for filling.
	- The first case is offset and count are byte aligned, meaning we can directly
	  use `buffer.fill`.
	- The second case is when we can acheive the action in one write call (i.e.,
	  we only ever need to write `00000000` or `11111111`, and the width is <= 53,
	  the maximum write width, either this or the count is less than eight, in that
	  case there is only ever up to one occurance of the value being written, so there
	  is no need to do excess calculations)
	- The third case will write the first `x` bits till it's byte aligned, then use
	  `buffer.fill` to write the main bulk, then write the last `n` unaligned bits.
]]
local BUFFER_FILL = [[--[=[
	Sets the `count` bits in the buffer starting at the specified ‘offset’ to the ‘value’.

	If `count` is ‘nil’ or is omitted, all bytes from the specified offset until the end of the buffer are set.
]=]
function bitbuffer.fill(b: buffer, offset: number, value: number, count: number?)
	local count: number = count or buffer.len(b) * 8 - offset

	local bit = offset % 8
	if bit == 0 and count % 8 == 0 then
		buffer.fill(b, offset // 8, value, count // 8)
	elseif count <= 8 then
		bitbuffer.writeu[count](b, offset, value)
	elseif count <= 53 and (value == 0 or value == 255) then
		bitbuffer.writeu[count](b, offset, if value == 255 then 2^count - 1 else 0)
	else
		local preWidth = 8 - bit
		local postWidth = (count + bit) % 8

		local mid = value
		if value ~= 0 and value ~= 255 then
			local a = POWERS_OF_TWO[preWidth]
			mid = (value // a) + (value % a * POWERS_OF_TWO[bit]) -- i.e., ABCDE-FGH -> FGH-ABCDE when `bit` is `3`
		end

		bitbuffer.writeu8(b, offset, value)

		local midWidthBytes = ( count - preWidth ) // 8
		if midWidthBytes > 0 then
			local offsetMid = ( offset + preWidth ) // 8
			buffer.fill(b, offsetMid, mid, midWidthBytes)
		end

		if postWidth > 0 then
			local offsetPost = offset + preWidth + midWidthBytes * 8
			bitbuffer.writeu[postWidth](b, offsetPost, mid)
		end
	end
end]]

-- stylua: ignore
--[[
	There are three cases for copying.
	- The first case is all the values are byte aligned, meaning we can
	  directly use `buffer.copy`.
	- The second case is the `target` and `source` bit are equal, which means
	  we can write the first `x` bits till we're byte aligned, then use `buffer.fill`
	  then write the last `y` bits.
	- The third case is the slowest and most common, the offsets can't be aligned
	  at the same time, so we align the offset target offset by writing the first
	  `n` bits, then write in chunks of 3 bytes at once, then write the remaining
	  unaligned bits.
]]
local BUFFER_COPY = [[--[=[
	Copy `count` bytes from ‘source’ starting at offset ‘sourceOffset’ into the ‘target’ at ‘targetOffset’.

	Unlike `buffer.copy`, it is not possible for ‘source’ and ‘target’ to be the same and then copy an overlapping region. This may be added in future.

	If ‘sourceOffset’ is nil or is omitted, it defaults to 0.

	If `count` is ‘nil’ or is omitted, the whole ‘source’ data starting from ‘sourceOffset’ is copied.
]=]
function bitbuffer.copy(target: buffer, targetOffset: number, source: buffer, sourceOffset: number?, count: number?)
	local sourceOffset = sourceOffset or 0
	local count = count or buffer.len(source) * 8 - sourceOffset

	local targetBit, sourceBit = targetOffset % 8, sourceOffset % 8
	if targetBit == 0 and sourceBit == 0 and count % 8 == 0 then
		buffer.copy(target, targetOffset // 8, source, sourceOffset // 8, count // 8)
	elseif count <= 53 then
		local value = bitbuffer.readu[count](source, sourceOffset)
		bitbuffer.writeu[count](target, targetOffset, value)
	elseif targetBit == sourceBit then
		local preWidth = 8 - targetBit
		local postWidth = (count + targetBit) % 8

		if preWidth > 0 then
			local value = bitbuffer.readu8(source, sourceOffset)
			bitbuffer.writeu8(target, targetOffset, value)
		end

		local midWidthBytes = ( count - preWidth ) // 8
		if midWidthBytes > 0 then
			local targetMid, sourceMid = ( targetOffset + preWidth ) // 8, ( sourceOffset + preWidth ) // 8
			buffer.copy(target, targetMid, source, sourceMid, midWidthBytes)
		end

		if postWidth > 0 then
			local totalOffset = preWidth + midWidthBytes * 8
			local targetPost, sourcePost = targetOffset + totalOffset, sourceOffset + totalOffset

			local value = bitbuffer.readu[postWidth](source, sourcePost)
			bitbuffer.writeu[postWidth](target, targetPost, value)
		end
	else
		local preWidth = 8 - targetBit
		local postWidth = (count + targetBit) % 8

		if preWidth > 0 then
			local value = bitbuffer.readu[preWidth](source, sourceOffset)
			bitbuffer.writeu[preWidth](target, targetOffset, value)
		end

		local targetByte = ( targetOffset + preWidth ) // 8
		local sourceBit = sourceOffset + preWidth

		local alignedCount = ( count - preWidth ) // 8
		local chunkCount = alignedCount // 3 * 3

		local readByte, readBit = sourceBit // 8, sourceBit % 8
		for byteOffset = 0, chunkCount - 1, 3 do
			local value = bit32_extract(readu32(source, readByte + byteOffset), readBit, 24)
			writeu24(target, targetByte + byteOffset, value)
		end

		local overflow = count - preWidth - chunkCount * 8
		if overflow > 0 then
			local value = bitbuffer.readu[overflow](source, sourceBit + chunkCount * 8)
			bitbuffer.writeu[overflow](target, (targetByte + chunkCount) * 8, value)
		end
	end
end]]

local function create()
	local output = {}
	table.insert(output, CONSTANTS)
	table.insert(output, BUFFER_FILL)
	table.insert(output, BUFFER_COPY)
	return output
end

return create
