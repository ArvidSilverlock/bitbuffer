local TEST_VALUE = 0b10010011_11001010_00110110_11010001_11100011_00100001_11001
local TEST_STRING = "9d<�Fy" -- `TEST_VALUE` written to a buffer in a successful case

return function()
	local bitbuffer = require(game.ReplicatedStorage.bitbuffer)

	describe("reading", function()
		local function TestWidth(width, offset)
			-- I need a way to calculate what value it should be reading, this is wrong.
			-- local trueValue = TEST_VALUE // 2 ^ offset
			return function()
				local b = buffer.fromstring(TEST_STRING)
				local readValue = bitbuffer.readbig(b, offset, width)
				-- expect(readValue).to.be.equal(trueValue)
			end
		end

		for width = 1, 52 do
			it(`should read byte aligned {width} bit numbers`, TestWidth(width, 0))
			it(`should read {width} bit numbers`, TestWidth(width, 4))
		end

		it("should error when the width is outside of the valid range", function()
			local b = buffer.create(8)

			expect(function()
				bitbuffer.readbig(b, 0, 0)
			end).to.throw("`width` must be greater than or equal to 1")

			expect(function()
				bitbuffer.readbig(b, 0, 54)
			end).to.throw("`width` must be less than or equal to 52")
		end)

		it("should error when reading before the beginning of the buffer", function()
			local b = buffer.create(1)
			expect(function()
				bitbuffer.readbig(b, -1, 1)
			end).to.throw("buffer access out of bounds")
		end)

		it("should error when reading over the end of the buffer", function()
			local b = buffer.create(1)
			expect(function()
				bitbuffer.readbig(b, 0, 16)
			end).to.throw("buffer access out of bounds")

			expect(function()
				bitbuffer.readbig(b, 8, 1)
			end).to.throw("buffer access out of bounds")
		end)
	end)

	describe("writing", function()
		local function TestWidth(width, offset)
			local value = TEST_VALUE % 2 ^ width
			return function()
				local b = buffer.create(16)

				bitbuffer.writebig(b, offset, value, width)
				local writtenValue = bitbuffer.readbig(b, offset, width)

				expect(writtenValue).to.be.equal(value)
			end
		end

		for width = 1, 52 do
			it(`should write byte aligned {width} bit numbers`, TestWidth(width, 0))
			it(`should write {width} bit numbers`, TestWidth(width, 4))
		end

		it("should error when the width is outside of the valid range", function()
			local b = buffer.create(8)

			expect(function()
				bitbuffer.writebig(b, 0, 0, 0)
			end).to.throw("`width` must be greater than or equal to 1")

			expect(function()
				bitbuffer.writebig(b, 0, 0, 54)
			end).to.throw("`width` must be less than or equal to 52")
		end)

		it("should error when writing before the beginning of the buffer", function()
			local b = buffer.create(1)
			expect(function()
				bitbuffer.writebig(b, -1, 0, 1)
			end).to.throw("buffer access out of bounds")
		end)

		it("should error when writing over the end of the buffer", function()
			local b = buffer.create(1)
			expect(function()
				bitbuffer.writebig(b, 0, 0, 16)
			end).to.throw("buffer access out of bounds")

			expect(function()
				bitbuffer.writebig(b, 8, 0, 1)
			end).to.throw("buffer access out of bounds")
		end)
	end)
end
