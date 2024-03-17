local NUMBER_TO_BASE64 = buffer_fromstring("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")
local BASE64_TO_NUMBER = {}

local CHARACTER_TO_BINARY = {}
local BINARY_TO_NUMBER = {}

local CHARACTER_TO_HEXADECIMAL = {}
local HEXADECIMAL_TO_NUMBER = {}

for index = 0, 255 do
	local binary = table.create(8)
	for field = 0, 7 do
		binary[field + 1] = bit32_extract(index, field, 1)
	end

	local binaryString = table.concat(binary)
	local hexadecimalString = string.format("%02x", index)

	local char = string.char(index)

	CHARACTER_TO_BINARY[char] = binaryString
	BINARY_TO_NUMBER[binaryString] = index

	CHARACTER_TO_HEXADECIMAL[char] = hexadecimalString
	HEXADECIMAL_TO_NUMBER[hexadecimalString] = index
end

for index = 0, 63 do
	BASE64_TO_NUMBER[readu8(NUMBER_TO_BASE64, index)] = index
end

local function baseLookupGenerator(default: { [string]: string })
	local cache = { [""] = default }

	return function(separator: string): { [string]: string }
		if cache[separator] then
			return cache[separator]
		end

		local lookupTable = {}
		for index = 0, 255 do
			local char = string.char(index)
			lookupTable[char] = default[char] .. separator
		end

		cache[separator] = lookupTable
		return lookupTable
	end
end
