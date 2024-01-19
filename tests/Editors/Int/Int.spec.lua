return function()
	local bitbuffer = require(game.ReplicatedStorage.bitbuffer)

	local b = buffer.create(4096)
	local writer = bitbuffer.writer(b)
	local reader = bitbuffer.reader(b)

	local function TestWidth(width, byteAligned)
		local minValue = -2 ^ (width - 1)
		local maxValue = 2 ^ (width - 1) - 1

		if not byteAligned then
			writer:Skip(1)
			reader:Skip(1)
		end

		return function()
			writer:Int(minValue, width)
			expect(reader:Int(width)).to.be.equal(minValue)

			writer:Int(0, width)
			expect(reader:Int(width)).to.be.equal(0)

			writer:Int(maxValue, width)
			expect(reader:Int(width)).to.be.equal(maxValue)

			writer:Align()
			reader:Align()
		end
	end

	for width = 1, 52 do
		it(`should write byte aligned {width} bit numbers`, TestWidth(width, true))
		it(`should write {width} bit numbers`, TestWidth(width, false))
	end
end
