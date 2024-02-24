return function(b, bitbuffer, test, testbase, random, randomString, testCount)
	local source = buffer.create(16)
	for offset = 0, 15 do
		buffer.writeu8(source, offset, math.random(0, 255))
	end

	for count = 1, 120 do
		for sourceOffset = 0, 7 do
			for targetOffset = 0, 7 do
				buffer.fill(b, 0, 0)
				bitbuffer.copy(b, 0, targetOffset, source, 0, sourceOffset, count)

				local endOffset = count // 8
				local overhang = count - endOffset * 8

				for chunkOffset = 0, endOffset - 1 do
					local sourceChunk = bitbuffer.readu8(source, chunkOffset, sourceOffset)
					local targetChunk = bitbuffer.readu8(b, chunkOffset, targetOffset)
					if sourceChunk ~= targetChunk then
						error(`{sourceChunk} ~= {targetChunk} ({count}, {sourceOffset}, {targetOffset})`)
					end
				end

				if overhang > 0 then
					local readOverhang = bitbuffer.readu[overhang]
					local sourceChunk = readOverhang(source, endOffset, sourceOffset)
					local targetChunk = readOverhang(b, endOffset, targetOffset)
					if sourceChunk ~= targetChunk then
						error(`{sourceChunk} ~= {targetChunk} (overhang, {count}, {sourceOffset}, {targetOffset})`)
					end
				end
			end
		end
	end
end
