return function()
	local bitbuffer = require(game.ReplicatedStorage.bitbuffer)

	describe("tobinary", function()
		local b = buffer.fromstring("Hello, World!")
		local str = bitbuffer.tobinary(b, "")
		expect(str).to.be.equal(
			"00010010101001100011011000110110111101100011010000000100111010101111011001001110001101100010011010000100"
		)
	end)

	describe("fromhex", function()
		local b = buffer.fromstring("Hello, World!")
		local str = bitbuffer.tohex(b, "")
		expect(str).to.be.equal("12a63636f63404eaf64e362684")
	end)

	describe("tobase64", function()
		local b = buffer.fromstring("foobar!")
		local str = bitbuffer.tobase64(b, "")
		expect(str).to.be.equal("Zm9vYmFyIQ==")

		local b = buffer.fromstring("hello")
		local str = bitbuffer.tobase64(b, "")
		expect(str).to.be.equal("aGVsbG8=")

		local b = buffer.fromstring("foo")
		local str = bitbuffer.tobase64(b, "")
		expect(str).to.be.equal("Zm9v")
	end)
end
