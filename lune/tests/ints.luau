return function(b, bitbuffer, test, testbase, random, randomString, testCount)
	for width = 2, 52 do
		local testInt = test(`i{width}`, bitbuffer.readi[width], bitbuffer.writei[width], math.round)
		local intMin = -2 ^ (width - 1)
		local intMax = -intMin - 1

		for _ = 1, testCount do
			testInt(random(intMin, intMax))
		end
	end
end
