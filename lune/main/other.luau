local BUFFER_FILL = [[function bitbuffer.fill(b: buffer, offset: number, value: number, count: number?)
	if offset % 8 == 0 and count % 8 == 0 then
		buffer.fill(b, offset // 8, value, count)
	else
		error("unimplemented")
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
	table.insert(output, BUFFER_FILL)
	table.insert(output, BUFFER_COPY)
	return output
end

return create
