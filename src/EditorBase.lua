--- @class Editor
local Editor = {}
Editor.__index = Editor

--[=[
	@method UpdateByteOffset
	@within Editor

	Updates internal values pertaining to whether the current `offset` is byte aligned.
]=]
function Editor:UpdateByteOffset()
	self._byte = bit32.rshift(self._offset, 3) -- offset // 8
	self._isByteAligned = not bit32.btest(self._offset, 0b111) -- offset % 8 == 0
end

--[=[
	@method SetOffset
	@within Editor

	@param offset number -- The new offset.
	@param updateByteOffset boolean? -- Whether or not to update information on the current byte, used internally to reduce unnecessary calculations.
]=]
function Editor:SetOffset(offset: number, updateByteOffset: boolean?)
	self._offset = offset
	if updateByteOffset ~= false then
		self:UpdateByteOffset()
	end
end

--[=[
	@method Skip
	@within Editor

	@param amount number -- The amount of bits to skip.
	@param updateByteOffset boolean? -- Whether or not to update information on the current byte, used internally to reduce unnecessary calculations.
]=]
function Editor:Skip(amount: number, updateByteOffset: boolean?)
	self:SetOffset(self._offset + amount, updateByteOffset)
end

--[=[
	@method Align
	@within Editor

	Aligns the current offset to the *next* byte, useful for a slight speed gain in some cases.
]=]
function Editor:Align()
	self:SetOffset(bit32.lshift(bit32.rshift(self._offset + 7, 3), 3)) -- math.ceil(self._offset / 8) * 8
end

return Editor
