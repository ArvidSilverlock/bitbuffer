return function(b, bitbuffer, test, testbase, random, randomString, testCount)
	local testf32 = test("f32", bitbuffer.readf32, bitbuffer.writef32, function(value)
		local interval = 2 ^ (math.floor(math.log(math.abs(value), 2)) - 23)
		return math.floor(value / interval) * interval
	end)

	for _, value in { 0, 0 / 0, -math.huge, math.huge, math.ldexp(1, -1024) } do
		testf32(value)
	end

	for _ = 1, testCount do
		testf32(random(-2 ^ 31, 2 ^ 31 - 1))
	end
end
