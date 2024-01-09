-- These make the `tostring` functions much faster, as it doesn't need to re-create the string forms
-- of all the numbers again, just reads if from the lookup tables.

local BASE64_VALUES = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local BINARY_LOOKUP = {}
local HEX_LOOKUP = {}
local BASE64_LOOKUP = {}

for i = 0, 255 do
	local binaryValue = table.create(8)
	for j = 7, 0, -1 do
		binaryValue[8 - j] = bit32.extract(i, j, 1)
	end
	local binaryString = table.concat(binaryValue)

	BINARY_LOOKUP[i] = binaryString
	HEX_LOOKUP[i] = string.format("%02x", i)
end

-- Convert the `BASE64_VALUES` string into a table.
for i = 0, 63 do
	BASE64_LOOKUP[i] = BASE64_VALUES:sub(i + 1, i + 1)
end

return {
	Binary = BINARY_LOOKUP,
	Hexadecimal = HEX_LOOKUP,
	Base64 = BASE64_LOOKUP,
}
