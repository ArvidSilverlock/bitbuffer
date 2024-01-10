# bitbuffer
Bit level manipulation of roblox's byte level buffers. :sunglasses:

Only truly supports `uints`, and, as of right now, I only plan to support `uints`, roblox's `bit32` library (one of the backbones of this whole module) doesn't support anything besides 32 bit unsigned integers.

## API

- read(buffer, offset, width)
- write(buffer, offset, value, width)

- fastread(buffer, offset, width)
- fastwrite(buffer, offset, value, width)

The offset that each function requires is a 0 indexed *bit* `offset`, the `width` is also in bits, which can range from 1-48, the `value` is an unsigned integer.

In most cases, like creating your own data from scratch, `fastread` and `fastwrite` would work fine, but when importing data generated externally, like for an LZW algorithm, or base64 decoder, `fastread` and `fastwrite` will most likely not read the data properly (due to the endian of `buffer`s being incorrect), only difference between these functions is the endian they use when storing data.

I'm not really too sure how to explain this properly, a more appropriate name for these functions would likely incorporate what endian they uses, like `bigread` and `littleread`, but these feel too verbose..? Again, I'm unsure.

## Base Conversion API

Currently there are 3 supported bases, binary, hexadecimal, and base64, each of which have `to` and `from` functions.

Functions that convert *to* a base intake a buffer and return a string, whereas the functions that do the inverse intake a string and return a buffer.
The `from` functions *do not* support prefixes or separators, this may come in the future, we'll have to see.

Each of the `to` functions take 3 parameters, the first being the buffer to convert, the second being the separator between each code, and the third being a prefix (or a boolean defining whether or not to add the default prefix). Only the first parameter is required, if the others aren't specified it will use defaults that make sense for each base.

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

## Writing non UInts

If you want to write values other than UInts, you could possibly use `string.pack` to convert non UInts to UInts, for example:
```lua
print(string.unpack("<I4", string.pack("<f", math.pi))) -- 1078530011
```
You can easily invert this process by flipping the pack formats around.

Obviously this is relatively slow, but I'm not all too sure if there's an alternative to doing this, as there's not really another way to read binary data.

## An few examples
```lua
local b = buffer.create(1)

bitbuffer.write(b, 0, 1, 1) -- Write 1 bit at the first bit.
assert(bitbuffer.read(b, 0, 1) == 1) -- Validate the write call functioned

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
- support up to 53 bit integers, instead of up 48 bit integers
- some form of function that allows for better formatting like `0000 000000 00000000` (i.e., chunks of information are split into groups specified by the user, good if you have a set scheme for your data)
- given the nature of this module, testez is probably a good idea