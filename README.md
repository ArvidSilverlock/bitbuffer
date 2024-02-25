## bitbuffer
Bit level manipulation of buffers 😎

1:1 recreation of the `buffer` api for the bit level, includes all functions except `len`, `create`, `tostring` and `fromstring`, as there is no way to make a bit level counterpart for them, if there is (i.e., `len`), I consider it to be redundant.

`writeu` allows for widths ranging from 1 to 53, whereas `writei` only allows widths 2 to 52. UInts can only be written up to 52 bytes due to precision issues when calculating the 2's compliment of the number.

If you want to use a combined byte/bit offset, you can merley use this idiv and mod to separate it when calling the function `bitbuffer.writeu(b, offset // 8, offset % 8, value)`, the reason this isn't done internally is to allow for extra micro-optimization when using this module.

Can be installed with wally using `arvidsilverlock/bitbuffer@latest`

## Current Version - 0.1.1
0.1.0 was taken due to mistakes made early into development.

I'm unsure whether the `index.d.ts` file is entirely functional, other than that, I'm fairly sure all other features should work as intended(?).
Note that this version doesn't include the `Reader:String()` and `Writer:String()` functions, as these are missing due to an oversight.

Changes since the previous version include:
- Swapping the combined byte/bit `offset` into a separate one, to allow for more optimizations on the user end.
- Addition of `bitbuffer.reader` and `bitbuffer.writer` classes that entirely abstract the lower level functions and handling of offsets.
- The addition of partial typescript support.

Known issues:
- `UDim2`s do not function for the `Reader` and `Writer` classes.