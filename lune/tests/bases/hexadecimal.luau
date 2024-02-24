return function(b, bitbuffer, test, testbase, random, randomString, testCount)
	testbase(bitbuffer.tohexadecimal, bitbuffer.fromhexadecimal, {})
end
