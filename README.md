# bitbuffer
Bit level manipulation of roblox's byte level buffers. :sunglasses:

## Basic API

- read(buffer, offset, width)
- write(buffer, offset, value, width)

- readlittle(buffer, offset, width)
- writelittle(buffer, offset, value, width)

The offset that each function requires is a 0 indexed *bit* `offset`, the `width` is also in bits, which can range from 1-48, the `value` is an unsigned integer.

`read` and `write` use big endian, whereas `readlittle` and `writelittle` use little endian. `readlittle` and `writelittle` are faster than their big endian counterparts as roblox's `buffer` objects seemingly use little endian on the byte scale, therefore less manipulation of the buffers is required. I'm not all too sure on any of this, as I'm not educated on the subject of endianness.

## Base Conversion API

Currently there are 3 supported bases, binary, hexadecimal, and base64, each of which have `to` and `from` functions.

Functions that convert *to* a base intake a buffer and return a string, whereas the functions that do the inverse intake a string and return a buffer.
The `from` functions *do not* support prefixes or separators, this may come in the future, we'll have to see.

Each of the `to` functions take 3 parameters, the first being the buffer to convert, the second being the separator between each code, and the third being a prefix (or a boolean defining whether or not to add the default prefix). Only the first parameter is required, if the others aren't specified it will use defaults that make sense for each base.

For byte aligned functions, such as `tobinary` and `tohex`, you are allowed to specify whether or not to flip the endian of the bytes being read, this is useful if you are using the little endian `read` and `write` calls and want to debug.

An example of how these format functions could look
```lua
print(bitbuffer.tobinary(b)) -- 11110011_10100110_00110100_01011010
print(bitbuffer.tobinary(b, " ")) -- 11110011 10100110 00110100 01011010

print(bitbuffer.tohex(b)) -- f3 a6 34 5a
print(bitbuffer.tohex(b, "")) -- f3a6345a

print(bitbuffer.tobase64(b)) -- 86Y0Wg==

-- You can do this trick to easily copy paste the actual number values for debugging.
print(bitbuffer.tobinary(b, ", 0b", true)) -- 0b11110011, 0b10100110, 0b00110100, 0b01011010
print(bitbuffer.tohex(b, ", 0x", true)) -- 0xf3, 0xa6, 0x34, 0x5a
```

## An few examples
```lua
local b = buffer.create(1)

bitbuffer.write(b, 0, 1, 1) -- Write 1 bit at the first bit.
assert(bitbuffer.read(b, 0, 1) == 1) -- Validate the write call functioned as expected

print(bitbuffer.tobinary(b)) -- 10000000
print(bitbuffer.tohex(b)) -- 80
```

```lua
local b = buffer.fromstring("foobar")

local encoded = bitbuffer.tobase64(b, "")
local decoded = bitbuffer.frombase64(encoded)

assert(bitbuffer.tohex(b) == bitbuffer.tohex(decoded))

print(encoded) -- Zm9vYmFy
```

## TODO:
- some form of function that allows for better formatting like `0000 000000 00000000` (i.e., chunks of information are split into groups specified by the user, good if you have a set scheme for your data)
- given the nature of this module, testez is probably a good idea