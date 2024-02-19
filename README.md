# bitbuffer
Bit level manipulation of buffers :sunglasses:

1:1 recreation of the `buffer` api for the bit level, includes all functions except `len`, `create`, `tostring` and `fromstring`.

`writeu` allows for widths ranging from 1 to 53, whereas `writei` only allows widths 2 to 52. UInts can only be written up to 52 bytes due to precision issues when calculating the 2's compliment of the number.

Can be installed with wally using `arvidsilverlock/bitbuffer@0.0.2`

The `f16` and `f32` functions are currently broken for certain cases, this will be fixed for 0.0.3
