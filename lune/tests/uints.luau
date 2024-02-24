return function(b, bitbuffer, test, testbase, random, randomString, testCount)
	for width = 1, 53 do
		local testUInt = test(`u{width}`, bitbuffer.readu[width], bitbuffer.writeu[width], math.round)
		local uintMax = 2 ^ width - 1

		for _ = 1, testCount do
			testUInt(random(0, uintMax))
		end
	end
end
