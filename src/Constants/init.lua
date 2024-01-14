local BaseConversion = require(script.BaseConversion)
local CFrameSpecialCases = require(script.CFrameSpecialCases)
local Enums = require(script.Enums)

local POWERS_OF_TWO = {}
for i = 0, 64 do
	POWERS_OF_TWO[i] = 2 ^ i
end

return {
	Binary = BaseConversion.Binary,
	Hexadecimal = BaseConversion.Hexadecimal,
	Base64 = BaseConversion.Base64,

	FlipEndian = BaseConversion.FlipEndian,
	PowersOfTwo = POWERS_OF_TWO,

	Enums = Enums.Enums,
	EnumToValue = Enums.EnumToValue,
	ValueToEnum = Enums.ValueToEnum,

	CFrameSpecialCases = CFrameSpecialCases,
}
