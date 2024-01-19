return function()
	local bitbuffer = require(game.ReplicatedStorage.bitbuffer)

	local b = buffer.create(64)
	local writer = bitbuffer.writer(b)
	local reader = bitbuffer.reader(b)

	it("should be capable of writing both `-math.huge` and `math.huge`", function()
		writer:Float32(math.huge)
		writer:Float32(-math.huge)

		expect(reader:Float32()).to.be.equal(math.huge)
		expect(reader:Float32()).to.be.equal(-math.huge)
	end)

	it("should be capable of writing `nan`", function()
		writer:Float32(0 / 0)

		local value = reader:Float32()
		expect(value).never.to.be.equal(value)
	end)

	it("should be capable of writing 'subnormal' numbers", function()
		local value = math.pi * 2 ^ -128
		writer:Float32(value)

		expect(reader:Float32()).to.be.near(value)
	end)

	it("should be capable of writing numbers", function()
		local value = math.pi
		writer:Float32(value)

		expect(reader:Float32()).to.be.near(value)
	end)
end
