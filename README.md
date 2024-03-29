## bitbuffer
Bit level manipulation of buffers 😎

1:1 recreation of the `buffer` api for the bit level, includes all functions except `len`, `create`, `tostring` and `fromstring`, as there is no use for a bit level counterpart.

`writeu` and `writei` allows for widths ranging from 1 to 53. Writing an `i53` doesn't use 2's compliment for the format, due to f64 precision issues.

If you want to use a combined byte/bit offset, you can merley use this idiv and mod to separate it when calling the function `bitbuffer.writeu(b, offset // 8, offset % 8, value)`, the reason this isn't done internally is to allow for extra micro-optimization when using this module. Other ways to handle offsets are included [here](exampes/handling_offset.md).

Can be installed with wally using `arvidsilverlock/bitbuffer@latest`

## Current Version - 0.1.2
Changes since the previous version include:
- Inlining `writeu` and `readu` functions when used internally (except for `Reader` and `Writer` classes)
- Inlining `IncrementOffset` within `Reader` and `Writer` classes.
- Removal of the localisation of `buffer.read` calls, this has no effect on performance.
- Adding an `Offset` class which handles your offset for you, `Reader` and `Writer` inherit from this.
- The `buffer`, `byte` and `bit` values present in `Reader`s and `Writer`s are no longer considered private.