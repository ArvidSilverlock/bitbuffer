local function case(x, y, z)
	return CFrame.fromEulerAnglesYXZ(math.rad(x), math.rad(y), math.rad(z))
end

local CFRAME_SPECIAL_CASES = {
	case(0, 0, 0),
	case(90, 0, 0),
	case(0, 180, 180),
	case(-90, 0, 0),
	case(0, 180, 90),
	case(0, 90, 90),
	case(0, 0, 90),
	case(0, -90, 90),
	case(-90, -90, 0),
	case(0, -90, 0),
	case(90, -90, 0),
	case(0, 90, 180),
	case(0, 180, 0),
	case(-90, -180, 0),
	case(0, 0, 180),
	case(90, 180, 0),
	case(0, 0, -90),
	case(0, -90, -90),
	case(0, -180, -90),
	case(0, 90, -90),
	case(90, 90, 0),
	case(0, 90, 0),
	case(-90, 90, 0),
	case(0, -90, 180),
}

local ENUM_CODES = {}
local ENUM_WIDTHS = {}
local ENUM_LOOKUP = {}

local enums = Enum:GetEnums()
for index, enum in enums do
	local enumItems = enum:GetEnumItems()
	ENUM_LOOKUP[enum] = table.create(#enumItems)

	ENUM_CODES[enum] = index - 1
	ENUM_WIDTHS[enum] = math.ceil(math.log(#enumItems, 2))

	for _, enumItem in enumItems do
		ENUM_LOOKUP[enum][enumItem.Value + 1] = enumItem
	end
end

local ENUM_CODE_WIDTH = math.ceil(math.log(#enums, 2))

return {
	Enums = enums,
	EnumCodes = ENUM_CODES,
	EnumWidths = ENUM_WIDTHS,
	EnumLookup = ENUM_LOOKUP,
	EnumCodeWidth = ENUM_CODE_WIDTH,

	CFrameSpecialCases = CFRAME_SPECIAL_CASES,
}
