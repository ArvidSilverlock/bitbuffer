local Writer = {}
Writer.__index = Writer

local function UInt(width: number)
	return function(self, value: number)
		self:UInt(value, width)
	end
end

local function Int(width: number)
	local min = -2 ^ (width - 1)
	return function(self, value: number)
		self:UInt(if value < 0 then value - min else value, width)
	end
end

local function Float(exponentWidth: number, fractionWidth: number)
	local fractionToUInt = 2 ^ fractionWidth
	local combinedWidth = exponentWidth + fractionWidth
	local totalWidth = combinedWidth + 1

	local exponentMax = (2 ^ exponentWidth - 1)
	local nanBits = 2 ^ combinedWidth - 1

	return function(self, value: number)
		if value == 0 then
			self:UInt(0, totalWidth)
		elseif value == math.huge then
			self:UInt(if value < 0 then 1 else 0, 1)
			self:UInt(exponentMax, exponentWidth)
			self:UInt(0, fractionWidth)
		elseif value ~= value then
			self:UInt(0, 1)
			self:UInt(nanBits, combinedWidth)
		else
			local fraction, exponent = math.frexp(value)
			self:UInt(if value < 0 then 1 else 0, 1)
			self:UInt(exponent, exponentWidth)
			self:UInt(math.ceil(math.abs(fraction) * fractionToUInt), fractionWidth)
		end
	end
end

function Writer:UInt(value: number, width: number)
	self.write(self._buffer, self._offset, value, width)
	self._offset += width
end

Writer.UInt8 = UInt(8)
Writer.UInt16 = UInt(16)
Writer.UInt24 = UInt(24)
Writer.UInt32 = UInt(32)

function Writer:Int(value: number, width: number)
	self:UInt(if value < 0 then value + 2 ^ (width - 1) else value, width)
end

Writer.Int8 = Int(8)
Writer.Int16 = Int(16)
Writer.Int24 = Int(24)
Writer.Int32 = Int(32)

Writer.Float16 = Float(5, 10)
Writer.Float32 = Float(8, 23)
Writer.Float64 = Float(11, 52)

return Writer
