return function()
	local bitbuffer = require(game.ReplicatedStorage.bitbuffer)

	local b = buffer.create(64)
	local writer = bitbuffer.writer(b)
	local reader = bitbuffer.reader(b)

	local function TestWidth(byteAligned)
		local minValue = -2 ^ 31
		local maxValue = 2 ^ 31 - 1

		if not byteAligned then
			writer:Skip(1)
			reader:Skip(1)
		end

		return function()
			writer:Int32(minValue)
			expect(reader:Int32()).to.be.equal(minValue)

			writer:Int32(0)
			expect(reader:Int32()).to.be.equal(0)

			writer:Int32(maxValue)
			expect(reader:Int32()).to.be.equal(maxValue)

			writer:Align()
			reader:Align()
		end
	end

	it(`should write byte aligned numbers`, TestWidth(true))
	it(`should write numbers`, TestWidth(false))
end
