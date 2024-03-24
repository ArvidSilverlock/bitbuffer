return function(b, bitbuffer, test, testbase, random, randomString, testCount)
	local testf16 = test("f16", bitbuffer.readf16, bitbuffer.writef16, function(value)
		local interval = 2 ^ (math.floor(math.log(math.abs(value), 2)) - 10)
		return math.floor(value / interval) * interval
	end)

	for _, value in { 0, 0 / 0, -math.huge, math.huge, math.ldexp(1, -1024) } do
		testf16(value)
	end

	for _ = 1, testCount do
		testf16(random(-2 ^ 31, 2 ^ 31 - 1))
	end
end
