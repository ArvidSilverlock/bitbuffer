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
	local count = count or (buffer.len(source) - targetByte) * 8 - targetBit
	local sourceByte = sourceByte or 0
	local sourceBit = sourceBit or 0

	if targetBit == 0 and sourceBit == 0 and count % 8 == 0 then
		buffer.copy(target, targetByte, source, sourceByte, count // 8)
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
			buffer.copy(target, targetByte + 1, source, sourceByte + 1, midWidthBytes)
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
		local chunkCount = alignedCount // 3 * 3

		-- Increment the `byte` and `bit` by `preWidth`
		sourceBit += preWidth
		sourceByte += sourceBit // 8
		sourceBit %= 8

		targetByte += 1

		for byteOffset = 0, chunkCount - 1, 3 do
			local value = bit32_extract(readu32(source, sourceByte + byteOffset), sourceBit, 24)
			writeu24(target, targetByte + byteOffset, value)
		end

		local overflow = count - preWidth - chunkCount * 8
		if overflow > 0 then
			local value = bitbuffer.readu[overflow](source, sourceByte + chunkCount, sourceBit)
			bitbuffer.writeu[overflow](target, targetByte + chunkCount, 0, value)
		end
	end
end
