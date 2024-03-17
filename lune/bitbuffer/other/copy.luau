--[=[
	Copy `count` bytes from ‘source’ starting at offset ‘sourceOffset’ into the ‘target’ at ‘targetOffset’.

	Unlike `buffer.copy`, it is not possible for ‘source’ and ‘target’ to be the same and then copy an overlapping region. This may be added in future.

	If ‘sourceOffset’ is nil or is omitted, it defaults to 0.

	If `count` is ‘nil’ or is omitted, the whole ‘source’ data starting from ‘sourceOffset’ is copied.
]=]
function bitbuffer.copy(
	target: buffer,
	targetByte: number,
	targetBit: number,
	source: buffer,
	sourceByte: number?,
	sourceBit: number?,
	count: number?
)
	local count = count or (buffer_len(source) - targetByte) * 8 - targetBit
	local sourceByte = sourceByte or 0
	local sourceBit = sourceBit or 0

	if targetBit == 0 and sourceBit == 0 and count % 8 == 0 then
		buffer_copy(target, targetByte, source, sourceByte, count // 8)
	elseif count <= 53 then
		local value = bitbuffer.readu[count](source, sourceByte, sourceBit)
		bitbuffer.writeu[count](target, targetByte, targetBit, value)
	elseif targetBit == sourceBit then
		local preWidth = 8 - targetBit
		local postWidth = (count + targetBit) % 8

		local value = bitbuffer.readu8(source, sourceByte, sourceBit)
		bitbuffer.writeu8(target, targetByte, targetBit, value)

		local midWidthBytes = (count - preWidth) // 8
		if midWidthBytes > 0 then
			buffer_copy(target, targetByte + 1, source, sourceByte + 1, midWidthBytes)
		end

		if postWidth > 0 then
			local value = bitbuffer.readu[postWidth](source, sourceByte + 1 + midWidthBytes, 0)
			bitbuffer.writeu[postWidth](target, targetByte + 1 + midWidthBytes, 0, value)
		end
	else
		local preWidth = 8 - targetBit

		local value = bitbuffer.readu8(source, sourceByte, sourceBit)
		bitbuffer.writeu8(target, targetByte, targetBit, value)

		local alignedCount = (count - preWidth) // 8
		local chunkCount = alignedCount // 6

		-- Increment the `byte` and `bit` by `preWidth`
		sourceBit += preWidth
		if sourceBit >= 8 then
			sourceByte += 1
			sourceBit -= 8
		end

		-- `targetBit` is implicitly 0
		targetByte += 1

		for _ = 1, chunkCount do
			local value = bit32_extract(readu32(source, sourceByte), sourceBit, 24)
				+ bit32_extract(readu32(source, sourceByte + 3), sourceBit, 24) * 0x1000000

			writeu32(target, targetByte, value)
			writeu16(target, targetByte + 4, value // 0x100000000)

			sourceByte += 6
			targetByte += 6
		end

		local overflow = count - preWidth - chunkCount * 48
		if overflow > 0 then
			local value = bitbuffer.readu[overflow](source, sourceByte, sourceBit)
			bitbuffer.writeu[overflow](target, targetByte, 0, value)
		end
	end
end
