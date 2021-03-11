# cl_khr_suggested_local_work_size test plan:

For each test scenario, execute the following sequence:

1. Query the suggested local work size.
2. Verify that the suggested local work size is valid for the device by comparing it against the value returned by `clGetKernelWorkGroupInfo(CL_KERNEL_WORK_GROUP_SIZE)`.
3. Enqueue an ND-range kernel with same parameters passed to the query and a `NULL` local work size.
The kernel can be simple and need only record the values returned by `get_enqueued_local_size()` (if supported) or `get_local_size()` (otherwise) to a buffer.
4. Verify that the local work size returned by the query match the local work size values written to the buffer.

Test scenarios should consist of:

* One-dimensional global work sizes in each dimension over a reasonable range of values (up to a small multiple of `CL_DEVICE_MAX_WORK_ITEM_SIZES` in the dimension?).
    * The range does not need to be exhaustive but should contain at least one value that is prime and exceeds `CL_DEVICE_MAX_WORK_GROUP_SIZE`.
* Two-dimensional and three-dimensional global work sizes over a reasonable range of values (up to a small multiple of `CL_DEVICE_MAX_WORK_GROUP_SIZE`?).
    * The ranges of values in each dimension can be even sparser but should contain some values that are prime and exceed `CL_DEVICE_MAX_WORK_GROUP_SIZE`.

For each global work size, test:

* Several different local memory requirements, taking into account `CL_DEVICE_LOCAL_MEM_SIZE`.
    * Possibly test statically allocated local memory in the kernel source by compiling several kernel variants?
    * Also test dynamically specified local memory passed as a kernel argument.
* Global work offset present and absent.
* A kernel that requires uniform work-groups (all devices) and that supports non-uniform work-groups (if supported).
