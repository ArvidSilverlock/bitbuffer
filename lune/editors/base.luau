function CLASS:IncrementOffset(amount: number)
	local byte, bit = amount // 8, amount % 8

	if bit == 0 then
		self._byte += byte
	else
		self._bit += bit
		self._byte += byte + self._bit // 8
		self._bit %= 8
	end
end

function CLASS:Align()
	if self._bit > 0 then
		self._byte += 1
		self._bit = 0
	end
end
