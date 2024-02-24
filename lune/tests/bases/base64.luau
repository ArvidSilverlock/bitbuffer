return function(b, bitbuffer, test, testbase, random, randomString, testCount)
	testbase(bitbuffer.tobase64, bitbuffer.frombase64, {
		["The quick brown fox jumps over the lazy dog."] = "VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZy4=",
		["foobar"] = "Zm9vYmFy",
		["glaggle"] = "Z2xhZ2dsZQ==",
		["a"] = "YQ==",
		["ab"] = "YWI=",
	})
end
