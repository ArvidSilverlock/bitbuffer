# bitbuffer
Bit level manipulation of buffers :sunglasses:

1:1 recreation of the `buffer` api for the bit level, includes all functions except `len`, `create`, `tostring` and `fromstring`, as there is no way to make a bit level counterpart for them, if there is (i.e., `len`), I consider it to be redundant.

`writeu` allows for widths ranging from 1 to 53, whereas `writei` only allows widths 2 to 52. UInts can only be written up to 52 bytes due to precision issues when calculating the 2's compliment of the number.

If you want to use a combined `byte`/`bit` offset, you can merley use this idiv and mod to separate it when calling the function `bitbuffer.writeu(b, offset // 8, offset % 8, value)`, the reason this isn't done internally is to allow for extra micro-optimization when using this module.

Can be installed with wally using `arvidsilverlock/bitbuffer@latest`
