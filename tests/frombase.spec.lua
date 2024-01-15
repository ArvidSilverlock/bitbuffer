return function()
	local bitbuffer = require(game.ReplicatedStorage.bitbuffer)

	describe("frombinary", function()
		local b = bitbuffer.frombinary(
			"01001000011001010110110001101100011011110010110000100000010101110110111101110010011011000110010000100001"
		)
		local str = buffer.tostring(b)
		expect(str).to.be.equal("Hello, World!")
	end)

	describe("tohex", function()
		local b = bitbuffer.fromhex("48656c6c6f2c20576f726c6421")
		local str = buffer.tostring(b)
		expect(str).to.be.equal("Hello, World!")
	end)

	describe("frombase64", function()
		local b = bitbuffer.frombase64("Zm9vYmFyIQ==")
		local str = buffer.tostring(b)
		expect(str).to.be.equal("foobar!")

		local b = bitbuffer.frombase64("aGVsbG8=")
		local str = buffer.tostring(b)
		expect(str).to.be.equal("hello")

		local b = bitbuffer.frombase64("Zm9v")
		local str = buffer.tostring(b)
		expect(str).to.be.equal("foo")
	end)
end
