return function(b, bitbuffer, test, testbase, random, randomString, testCount)
	for count = 1, 256, 28 do -- not byte aligned to test extra cases
		for value = 0, 255, 51 do
			for bit = 0, 7 do
				buffer.fill(b, 0, value)
				bitbuffer.fill(b, 0, bit, value, count)

				local endOffset = count // 8
				local overhang = count - endOffset * 8

				for chunkOffset = 0, endOffset - 1 do
					local chunk = bitbuffer.readu8(b, chunkOffset, bit)
					if chunk ~= value then
						error(`{chunk} ~= {value} ({count})`)
					end
				end

				if overhang > 0 then
					local chunk = bitbuffer.readu[overhang](b, endOffset, bit)
					local targetValue = value % 2 ^ overhang

					if chunk ~= targetValue then
						error(`{chunk} ~= {targetValue} ({count})`)
					end
				end
			end
		end
	end
end
