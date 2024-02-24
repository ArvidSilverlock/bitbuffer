return function(b, bitbuffer, test, testbase, random, randomString, testCount)
	local testf64 = test("f64", bitbuffer.readf64, bitbuffer.writef64)

	for _ = 1, testCount do
		testf64(random(-1024, 1024))
	end
end
