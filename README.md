## bitbuffer
Bit level manipulation of buffers 😎

1:1 recreation of the `buffer` api for the bit level, includes all functions except `len`, `create`, `tostring` and `fromstring`, as there is no way to make a bit level counterpart for them, if there is (i.e., `len`), I consider it to be redundant.

`writeu` allows for widths ranging from 1 to 53, whereas `writei` only allows widths 2 to 52. UInts can only be written up to 52 bytes due to precision issues when calculating the 2's compliment of the number.

If you want to use a combined byte/bit offset, you can merley use this idiv and mod to separate it when calling the function `bitbuffer.writeu(b, offset // 8, offset % 8, value)`, the reason this isn't done internally is to allow for extra micro-optimization when using this module.

Can be installed with wally using `arvidsilverlock/bitbuffer@latest`

## Current Version - 0.1.1
0.1.0 was taken due to mistakes made early into development.

I'm unsure whether the `index.d.ts` file is entirely functional, other than that, I'm fairly sure all other features should work as intended(?).

Changes since the previous version include:
- Swapping the combined byte/bit `offset` into a separate one, to allow for more optimizations on the user end.
- Addition of `bitbuffer.reader` and `bitbuffer.writer` classes that entirely abstract the lower level functions and handling of offsets.
- The addition of partial typescript support.

## Benchmarks
Ran on a Late 2013 iMac with a 3.2 GHz Quad-Core Intel Core i5 CPU.

These benchmarks are calculated by calling each function at every possible position in a buffer containing 65,536 bytes.
They were ran in native mode with the optimization level set to 2, this has roughly a 2x speed up in comparison to non-native mode and an optimization level of 0.

## Integer Read and Write Time (ns)
|bits|readu|writeu|readi|writei|
|----|-----|------|-----|------|
| 01 | 21.312 | 26.536 | N/A | N/A |
| 02 | 22.595 | 27.660 | 52.497 | 43.818 |
| 03 | 21.579 | 25.536 | 54.278 | 44.013 |
| 04 | 21.165 | 26.162 | 51.607 | 44.370 |
| 05 | 20.935 | 24.740 | 52.479 | 47.705 |
| 06 | 21.885 | 24.617 | 53.007 | 45.830 |
| 07 | 21.178 | 24.811 | 52.948 | 44.194 |
| 08 | 22.572 | 24.013 | 47.312 | 42.394 |
| 09 | 20.953 | 25.342 | 49.824 | 45.228 |
| 10 | 22.397 | 26.705 | 52.640 | 45.099 |
| 11 | 22.412 | 26.837 | 55.199 | 45.642 |
| 12 | 21.863 | 28.027 | 53.532 | 49.722 |
| 13 | 22.172 | 28.665 | 55.074 | 49.015 |
| 14 | 23.532 | 29.416 | 54.622 | 50.383 |
| 15 | 24.309 | 31.871 | 54.706 | 51.673 |
| 16 | 24.579 | 30.345 | 53.199 | 47.644 |
| 17 | 22.633 | 31.308 | 54.778 | 48.707 |
| 18 | 24.053 | 32.752 | 54.898 | 49.691 |
| 19 | 25.731 | 32.126 | 54.934 | 49.621 |
| 20 | 23.406 | 31.834 | 54.307 | 50.143 |
| 21 | 22.194 | 27.627 | 55.053 | 52.324 |
| 22 | 21.913 | 26.825 | 52.244 | 46.250 |
| 23 | 21.308 | 26.449 | 51.902 | 46.634 |
| 24 | 23.429 | 25.816 | 51.086 | 43.344 |
| 25 | 20.376 | 25.420 | 49.715 | 43.568 |
| 26 | 29.640 | 34.046 | 61.936 | 54.942 |
| 27 | 28.827 | 34.593 | 64.356 | 54.712 |
| 28 | 27.920 | 33.960 | 64.588 | 54.872 |
| 29 | 28.210 | 34.372 | 64.925 | 52.234 |
| 30 | 28.258 | 34.252 | 66.009 | 53.389 |
| 31 | 29.050 | 34.682 | 62.931 | 52.437 |
| 32 | 27.727 | 33.691 | 56.558 | 49.350 |
| 33 | 28.799 | 36.353 | 60.047 | 52.306 |
| 34 | 29.817 | 36.662 | 63.025 | 55.450 |
| 35 | 29.558 | 38.569 | 63.309 | 55.591 |
| 36 | 29.871 | 40.021 | 63.781 | 57.305 |
| 37 | 31.588 | 43.693 | 64.886 | 59.193 |
| 38 | 30.925 | 45.798 | 65.477 | 61.113 |
| 39 | 32.124 | 46.948 | 64.598 | 60.894 |
| 40 | 30.178 | 41.762 | 65.162 | 57.031 |
| 41 | 31.314 | 41.587 | 65.924 | 58.229 |
| 42 | 32.073 | 45.423 | 69.333 | 62.507 |
| 43 | 30.519 | 43.130 | 64.823 | 59.972 |
| 44 | 29.714 | 40.888 | 66.387 | 60.564 |
| 45 | 30.717 | 39.620 | 63.587 | 57.076 |
| 46 | 29.105 | 37.515 | 65.701 | 55.873 |
| 47 | 29.672 | 36.003 | 65.179 | 54.607 |
| 48 | 27.601 | 33.816 | 61.532 | 51.848 |
| 49 | 34.567 | 43.374 | 66.522 | 61.891 |
| 50 | 35.524 | 44.593 | 71.630 | 63.962 |
| 51 | 36.240 | 44.354 | 68.421 | 63.964 |
| 52 | 35.207 | 43.989 | 70.019 | 66.232 |
| 53 | 34.940 | 43.860 | N/A | N/A |

## Float Read and Write Time (ns)
|bits|read|write|
|----|----|-----|
| 16 | 97.877 | 112.280 |
| 32 | 91.054 | 100.778 |
| 64 | 101.716 | 105.626 |