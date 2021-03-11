# cl_khr_extended_bit_ops test plan:

Need to test each of the new built-in functions:

* `bitfield_insert`
* `bitfield_extract_signed`
* `bitfield_extract_unsigned`
* `bit_reverse`

Need to test each of the supported types.
Both scalar types and all vector types (2, 3, 4, 8, and 16 elements) are supported for each built-in function:

* `char` and `uchar`
* `short` and `ushort`
* `int` and `uint`
* `long` and `ulong` (when supported)

So, a total of 4 (type sizes) x 2 (signed and unsigned) x 6 (scalar and all vectors) = 48 types.

Proposal:

* Add a single new sub-test (to `test_basic`?) to test the extension.
    * No version checks; the test will run when the extension is supported.

* Run the tests below for each of the supported types.

* For `bitfield_insert`, exhaustively test all valid combinations of `offset` and `count`:
    * Exhaustive testing is possible because the valid values of `offset` and `count` range from 0 to 64 (inclusive) for 64-bit types, and smaller types require fewer tests.
        * 65 x 65 = 4225 cases, assign one case to each work-item.
    * For each work-item:
        * Extract `offset` and `count` from the global ID.
        * Clamp `count` to a valid value given `offset`.
        * Read the value of `insert` from a randomly constructed input buffer.
        * Read the value of `base` from an input buffer.  This shouldn't be random, but could be all-bits-set or some known pattern.
        * Call `bitfield_insert` with the values of `base`, `insert`, `offset`, and `count`.
        * Write the result to an output buffer.
    * Verify the results on the host.

* For `bitfield_extract_signed` and `bitfield_extract_unsigned`, test both functions together.
    * Also exhaustively test all valid combinations of `offset` and `count` - see above.
    * For each work-item:
        * Extract `offset` and `count` from the global ID.
        * Clamp `count` to a valid value given `offset`.
        * Read the value of `base` from a randomly constructed input buffer.
        * Call `bitfield_extract_signed` and `bitfield_extract_unsigned` with the values of `base`, `offset`, and `count`.
        * Write each result to a separate output buffer.
    * Verify the results on the host.

* For `bit_reverse`, test a reasonably large set of random data (size TBD but no more than 64K elements?):
    * Testing random data is sufficient since there are unlikely to be "special-case" elements.
    * If we prefer we could exhaustively test at least the 8-bit and 16-bit types.
    * Exhaustively testing the 32-bit types is probably doable but low-value.
    * Exhaustively testing the 64-bit types is not practical due to the problem size.
    * For each work-item:
        * Read the value of `base` from the input buffer.
        * Call `bit_reverse` with the value of `base`.
        * Write the result to an output buffer.
    * Verify the results on the host.
