local Offset = {}
Offset.__index = Offset

function bitbuffer.offset(byte: number?, bit: number?)
	local self = {}
	self.__index = self

	if byte and bit then
		self.byte, self.bit = byte, bit
	elseif byte then
		self.byte, self.bit = byte // 8, byte % 8
	else
		self.byte, self.bit = 0, 0
	end

	return setmetatable(self, Offset)
end

function Offset:SetOffset(byte: number, bit: number?)
	if bit then
		self.byte = byte
		self.bit = bit
	else
		self.byte = byte // 8
		self.bit = byte % 8
	end
end

function Offset:IncrementOffset(byte: number, bit: number?)
	if bit == nil then
		byte, bit = byte // 8, byte % 8
	end

	if bit == 0 then
		self.byte += byte
	else
		self.bit += bit
		if self.bit >= 8 then
			self.byte += byte + self.bit // 8
			self.bit %= 8
		else
			self.byte += byte
		end
	end
end

function Offset:Align()
	if self._bit > 0 then
		self._byte += 1
		self._bit = 0
	end
end
