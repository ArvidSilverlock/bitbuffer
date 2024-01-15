local TEST_VALUE = 0b10010011_11001010_00110110_11010001_11100011_00100001_11001

return function()
	local bitbuffer = require(game.ReplicatedStorage.bitbuffer)

	describe("reading", function()
		local function TestWidth(width, offset)
			-- Awful test case, need to make it better
			return function()
				local b = buffer.create(16)
				bitbuffer.read(b, offset, width)
			end
		end

		for width = 1, 53 do
			it(`should read byte aligned {width} bit numbers`, TestWidth(width, 0))
			it(`should read {width} bit numbers`, TestWidth(width, 4))
		end

		it("should error when the width is outside of the valid range", function()
			local b = buffer.create(8)

			expect(function()
				bitbuffer.read(b, 0, 0)
			end).to.throw("`width` must be greater than or equal to 1")

			expect(function()
				bitbuffer.read(b, 0, 54)
			end).to.throw("`width` must be less than or equal to 53")
		end)

		it("should error when reading before the beginning of the buffer", function()
			local b = buffer.create(1)
			expect(function()
				bitbuffer.read(b, -1, 8)
			end).to.throw("buffer access out of bounds")
		end)

		it("should error when reading over the end of the buffer", function()
			local b = buffer.create(1)
			expect(function()
				bitbuffer.read(b, 0, 16)
			end).to.throw("buffer access out of bounds")

			expect(function()
				bitbuffer.read(b, 8, 1)
			end).to.throw("buffer access out of bounds")
		end)
	end)

	describe("writing", function()
		local function TestWidth(width, offset)
			local value = TEST_VALUE % 2 ^ width
			return function()
				local b = buffer.create(16)

				bitbuffer.write(b, offset, value, width)
				local writtenValue = bitbuffer.read(b, offset, width)

				expect(writtenValue).to.be.equal(value)
			end
		end

		for width = 1, 53 do
			it(`should write byte aligned {width} bit numbers`, TestWidth(width, 0))
			it(`should write {width} bit numbers`, TestWidth(width, 4))
		end

		it("should error when the width is outside of the valid range", function()
			local b = buffer.create(8)

			expect(function()
				bitbuffer.write(b, 0, 0, 0)
			end).to.throw("`width` must be greater than or equal to 1")

			expect(function()
				bitbuffer.write(b, 0, 0, 54)
			end).to.throw("`width` must be less than or equal to 53")
		end)

		it("should error when writing before the beginning of the buffer", function()
			local b = buffer.create(1)
			expect(function()
				bitbuffer.write(b, -1, 0, 1)
			end).to.throw("buffer access out of bounds")
		end)

		it("should error when writing over the end of the buffer", function()
			local b = buffer.create(1)
			expect(function()
				bitbuffer.write(b, 0, 0, 16)
			end).to.throw("buffer access out of bounds")

			expect(function()
				bitbuffer.write(b, 8, 0, 1)
			end).to.throw("buffer access out of bounds")
		end)
	end)
end
