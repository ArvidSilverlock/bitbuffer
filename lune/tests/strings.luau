return function(b, bitbuffer, test, testbase, random, randomString, testCount)
	local teststring = test("string", bitbuffer.readstring, bitbuffer.writestring)
	for _ = 1, testCount do
		teststring(randomString())
	end
end
