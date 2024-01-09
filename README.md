# bitbuffer
Bit level manipulation of roblox's byte level buffers. :sunglasses:

Only truly supports `UInts`, and I only plan to support `UInts`, roblox's `bit32` library (one of the backbones of this whole module) doesn't support anything besides 32 bit unsigned integers.

## API

- read(buffer, offset, width)
- write(buffer, offset, value, width)

There are only two functions pertaining to modification of the buffer, `read` and `write`.
The offset that each function requires is a 0 indexed *bit* offset, the width is also in bits, the width can range from 1-48.

The reason the `write` function takes the `value` to write before the `width` is to more closely mimic the `bit32` library.

## Base Conversion API

There are three functions, `tobinary`, `tohex`, `tobase64`. Each of them take the same parameters, the `buffer` to convert to a string, an optional `separator` string which defines the character(s) to separate each chunk of the buffer by, and whether or not to add a base prefix (defaults to `true`).

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
assert(bitbuffer.write(b, 0, 1) == 1)

print(bitbuffer.tobinary(b)) -- 10000000
print(bitbuffer.tohex(b)) -- 80
```

## TODO:
- `frombase` functions
- `binaryformat`, allows for better formatting like `0000 000000 00000000` (i.e., chunks of information are split into groups by spaces specified by the user, good if you have a static scheme for your data)
- given the nature of this module, testez is probably a good idea