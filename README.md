# bitbuffer
Bit level manipulation of roblox's byte level buffers. :sunglasses:

Only truly supports `UInts`, and I only plan to support `UInts`, roblox's `bit32` library (one of the two backbones of this whole module) doesn't support anything besides 32 bit unsigned integers.

## Benchmarks
The following test cases were ran in 'native' mode with the optimisation level set to `2`.
Bare in mind direct buffer calls (in native) are ~20ns, so this is relatively slow.

|case                    |write (ns)|read (ns)|
|------------------------|----------|---------|
|byte aligned            |113.5     |115.3    |
|byte confined           |120.3     |162.2    |
|cross-byte              |276.1     |195.6    |
|end overhang            |84.7      |81.0     |
|end & beginning overhang|82.9      |82.1     |

## API

- read(buffer, offset, width)
- write(buffer, offset, value, width)

There are only two functions pertaining to modification of the buffer, `read` and `write`.
The offset that each function requires is a 0 indexed *bit* offset, the width is also in bits.

The reason the `write` function takes the `value` to write before the `width` is to more closely mimic the `bit32` library.

There is a grand total of **1** security check! So it will not prevent you from writing values out of the range of your specified width, not tested what happens.

## Base Conversion API

There are three functions, `tobinary`, `tohex`, `tobase64`, each takes a buffer as an input and outputs a string. The benchmarks for these three functions are as follows (ran on buffers of length 1,000):

|function   |time (μs)|
|-----------|---------|
|binary     |185.6    |
|hexadecimal|174.3    |
|base64     |272.5    |

## Writing non UInts

If you want to write values other than UInts, you could possibly use `string.pack` to convert non UInts to UInts, for example:
```lua
print(string.unpack("<I4", string.pack("<f", math.pi))) -- 1078530011
```
You can easily invert this process by flipping the pack formats around.

## An example
```lua
local b = buffer.create(1)

bitbuffer.write(b, 0, 1, 1) -- Write 1 bit at the first bit.
assert(buffer.readu8(b, 0) == 0b10000000)

print(bitbuffer.tobinary(b, " ")) -- 10000000
print(bitbuffer.tohex(b, " ")) -- 80
```
