# bitbuffer
Bit level manipulation of byte level buffers. :sunglasses:

## benchmarks
The following test cases were ran in 'native' mode with the optimisation level set to `2`.
Bare in mind direct buffer calls (in native) are ~0.02μs, so this is relatively slow.

|case                    |write (μs)|read (μs)|
|------------------------|----------|---------|
|byte aligned            |0.1135    |0.1153   |
|byte confined           |0.1203    |0.1622   |
|cross-byte              |0.2761    |0.1956   |
|end overhang            |0.0847    |0.0810   |
|end & beginning overhang|0.0829    |0.0821   |