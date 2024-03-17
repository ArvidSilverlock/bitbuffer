--[=[
	Sets the `count` bits in the buffer starting at the specified ‘offset’ to the ‘value’.

	If `count` is ‘nil’ or is omitted, all bytes from the specified offset until the end of the buffer are set.
]=]
function bitbuffer.fill(b: buffer, byte: number, bit: number, value: number, count: number?)
	local count: number = count or (buffer_len(b) - byte) * 8 - bit

	if bit == 0 and count % 8 == 0 then
		buffer_fill(b, byte, value, count // 8)
	elseif count <= 8 then
		bitbuffer.writeu[count](b, byte, bit, value)
	elseif count <= 53 and (value == 0 or value == 255) then
		bitbuffer.writeu[count](b, byte, bit, if value == 255 then 2 ^ count - 1 else 0)
	else
		local preWidth = 8 - bit
		local postWidth = (count + bit) % 8

		local mid = value
		if value ~= 0 and value ~= 255 then
			local a = POWERS_OF_TWO[preWidth]
			mid = (value // a) + (value % a * POWERS_OF_TWO[bit]) -- i.e., ABCDE-FGH -> FGH-ABCDE when `bit` is `3`
		end

		bitbuffer.writeu8(b, byte, bit, value) -- writing a static width of 8 rather than a variable width of `preWidth` is faster (we overwrite the extra bits written later)
		byte += 1 -- bit is also 0 now, but we don't need to set it since we no longer use the variable

		local midWidthBytes = (count - preWidth) // 8
		if midWidthBytes > 0 then
			buffer_fill(b, byte, mid, midWidthBytes)
			byte += midWidthBytes
		end

		if postWidth > 0 then
			bitbuffer.writeu[postWidth](b, byte, 0, mid)
		end
	end
end
