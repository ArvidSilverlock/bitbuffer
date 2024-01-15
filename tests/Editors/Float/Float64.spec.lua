return function()
	local bitbuffer = require(game.ReplicatedStorage.bitbuffer)

	local b = buffer.create(64)
	local writer = bitbuffer.writer(b)
	local reader = bitbuffer.reader(b)

	it("should be capable of writing both `-math.huge` and `math.huge`", function()
		writer:Float64(math.huge)
		writer:Float64(-math.huge)

		expect(reader:Float64()).to.be.equal(math.huge)
		expect(reader:Float64()).to.be.equal(-math.huge)
	end)

	it("should be capable of writing `nan`", function()
		writer:Float64(0 / 0)

		local value = reader:Float64()
		expect(value).never.to.be.equal(value)
	end)

	it("should be capable of writing 'denormal' numbers", function()
		local value = math.pi * 2 ^ -118
		writer:Float64(value)

		expect(reader:Float64()).to.be.equal(value)
	end)

	it("should be capable of writing numbers", function()
		local value = math.pi
		writer:Float64(value)

		expect(reader:Float64()).to.be.equal(value)
	end)
end
