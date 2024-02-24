return function(b, bitbuffer, test, testbase, random, randomString, testCount)
	local testf16 = test("f16", bitbuffer.readf16, bitbuffer.writef16, function(value)
		local interval = 2 ^ (math.floor(math.log(math.abs(value), 2)) - 10)
		return math.floor(value / interval) * interval
	end)

	for _ = 1, testCount do
		testf16(random(-1024, 1024))
	end
end
