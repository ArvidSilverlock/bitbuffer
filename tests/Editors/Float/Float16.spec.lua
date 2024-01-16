return function()
	local bitbuffer = require(game.ReplicatedStorage.bitbuffer)

	local b = buffer.create(64)
	local writer = bitbuffer.writer(b)
	local reader = bitbuffer.reader(b)

	it("should be capable of writing both `-math.huge` and `math.huge`", function()
		writer:Float16(math.huge)
		writer:Float16(-math.huge)

		expect(reader:Float16()).to.be.equal(math.huge)
		expect(reader:Float16()).to.be.equal(-math.huge)
	end)

	it("should be capable of writing `nan`", function()
		writer:Float16(0 / 0)

		local value = reader:Float16()
		expect(value).never.to.be.equal(value)
	end)

	it("should be capable of writing 'denormal' numbers", function()
		local value = math.pi * 2 ^ -32
		writer:Float16(value)

		expect(reader:Float16()).to.be.near(value, 0.0625)
	end)

	it("should be capable of writing numbers", function()
		local value = math.pi
		writer:Float16(value)

		expect(reader:Float16()).to.be.near(value, 0.0625)
	end)
end
