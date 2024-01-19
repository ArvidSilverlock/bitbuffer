return function()
	local bitbuffer = require(game.ReplicatedStorage.bitbuffer)

	local b = buffer.create(16)
	local writer = bitbuffer.writer(b)
	local reader = bitbuffer.reader(b)

	local function TestWidth(byteAligned)
		local minValue = -2 ^ 15
		local maxValue = 2 ^ 15 - 1

		if not byteAligned then
			writer:Skip(1)
			reader:Skip(1)
		end

		return function()
			writer:Int16(minValue)
			expect(reader:Int16()).to.be.equal(minValue)

			writer:Int16(0)
			expect(reader:Int16()).to.be.equal(0)

			writer:Int16(maxValue)
			expect(reader:Int16()).to.be.equal(maxValue)

			writer:Align()
			reader:Align()
		end
	end

	it(`should write byte aligned numbers`, TestWidth(true))
	it(`should write numbers`, TestWidth(false))
end
