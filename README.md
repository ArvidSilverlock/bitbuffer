# bitbuffer
Bit level manipulation of byte level buffers :sunglasses:

Capable of writing both signed and unsigned integers along with float32s and float64s.

`writeu` allows for widths ranging from 1 to 53, whereas `writei` only allows widths 2 to 52.
The reason for the different upper limit is when calculating the unsigned variant of the signed integer, if writing 53 bits, it will go outside of lua number's (float64) precision.

While the cost of using the `writeu` and `writei` functions over the hardcoded width functions (i.e., `writeu4`, `writei7`) is often negligable, if you need that microsecond speed increase of using the hardcoded width functions, you will see they take a separate `byte` and `bit` coordinate as their input, you can specify these as `bitOffset // 8` and `bitOffset % 8` respectively. The reason for this choice is that internally, some of the functions will call lower bit widths (to account for the `bit32` not functioning on more than 32 bits).

Soon I'll reimplement my `Reader` and `Writer` calls that can be found on the main branch, along with the base conversion functions, but given the lack of big endian reading some modification will be required.