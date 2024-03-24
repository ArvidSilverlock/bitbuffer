local CLASS = {}
CLASS.__index = CLASS

function CLASS:SetOffset(byte: number, bit: number?)
	if bit then
		self.byte = byte
		self.bit = bit
	else
		self.byte = byte // 8
		self.bit = byte % 8
	end
end

function CLASS:IncrementOffset(byte: number, bit: number?)
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

function CLASS:Align()
	if self.bit > 0 then
		self.byte += 1
		self.bit = 0
	end
end
