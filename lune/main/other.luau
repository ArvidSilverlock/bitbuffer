local CONSTANTS =
	[[local POWERS_OF_TWO = { [0] = 1, [1] = 2, [2] = 4, [3] = 8, [4] = 16, [5] = 32, [6] = 64, [7] = 128, [8] = 256 }]]

local BUFFER_FILL = [[function bitbuffer.fill(b: buffer, offset: number, value: number, count: number?)
	local count: number = count or buffer.len(b) * 8 - offset

	local bit = offset % 8
	if bit == 0 and count % 8 == 0 then
		buffer.fill(b, offset // 8, value, count // 8)
	elseif value == 0 and count <= 53 or count <= 8 then
		bitbuffer.writeu(b, offset, value, count)
	else
		local preWidth = 8 - bit
		local postWidth = (count + bit) % 8

		local mid = 0
		if value ~= 0 then
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
			bitbuffer.writeu(b, offsetPost, mid, postWidth)
		end
	end
end]]

-- stylua: ignore
local BUFFER_COPY = [[function bitbuffer.copy(target: buffer, targetOffset: number, source: buffer, sourceOffset: number?, count: number?)
	if targetOffset % 8 == 0 and sourceOffset % 8 == 0 and count % 8 == 0 then
		buffer.copy(target, targetOffset, source, sourceOffset, count)
	else
		error("unimplemented")
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
