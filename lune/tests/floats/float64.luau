return function(b, bitbuffer, test, testbase, random, randomString, testCount)
	local testf64 = test("f64", bitbuffer.readf64, bitbuffer.writef64)

	for _, value in { 0, 0 / 0, -math.huge, math.huge, math.ldexp(1, -1024) } do
		testf64(value)
	end

	for _ = 1, testCount do
		testf64(random(-2 ^ 31, 2 ^ 31 - 1))
	end
end
