return function(b, bitbuffer, test, testbase, random, randomString, testCount)
	testbase(bitbuffer.tobinary, bitbuffer.frombinary, {})
end
