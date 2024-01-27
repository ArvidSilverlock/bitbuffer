local function generateRead(output) end

local function generateWrite(output) end

local function finalise(output) end

return {
	read = generateRead,
	write = generateWrite,
	finalise = finalise,
}
