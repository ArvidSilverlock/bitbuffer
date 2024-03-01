local fs = require("@lune/fs")

local function get(fileName: string)
	return (fs.readFile(`lune/bitbuffer/other/{fileName}.luau`):gsub("\n$", ""))
end

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
local BUFFER_FILL = get("fill")

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
local BUFFER_COPY = get("copy")

local FILL_TYPE = [[fill: (b: buffer, byte: number, bit: number, value: number, count?: number) => void;]]
local COPY_TYPE = [[copy: (
	target: buffer,
	targetByte: number,
	targetBit: number,
	source: buffer,
	sourceByte?: number,
	sourceBit?: number,
	count?: number
) => void;]]

return function(luau, typescript)
	-- stylua: ignore start
	luau:Push(CONSTANTS)
		:Push("")
		:Push(BUFFER_FILL)
		:Push("")
		:Push(BUFFER_COPY)

	typescript:Push(FILL_TYPE)
		:Push("")
		:Push(COPY_TYPE)
		:Push("")
	-- stylua: ignore end
end
