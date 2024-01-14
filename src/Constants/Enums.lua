local ENUM_TO_VALUE = {}
local VALUE_TO_ENUM = {}

local enums = Enum:GetEnums()
for index, enum in enums do
	local enumItems = enum:GetEnumItems()
	local code = index - 1

	ENUM_TO_VALUE[enum] = code
	VALUE_TO_ENUM[code] = table.create(#enumItems)

	for _, enumItem in enumItems do
		VALUE_TO_ENUM[code][enumItem.Value] = enumItem
	end
end

return {
	Enums = enums,
	EnumToValue = ENUM_TO_VALUE,
	ValueToEnum = VALUE_TO_ENUM,
}
