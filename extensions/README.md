# OpenCL Extensions Source Repository

This is a Khronos repository for tracking discussion of extensions
to the OpenCL API, OpenCL C, and OpenCL C++ specifications.

The process for extending OpenCL is described below.  The recommended
format of an OpenCL extension is documented in the
[cl_extension_template.asciidoc](cl_extension_template.asciidoc) file, in this
repository.

## Format and Lifecycle of an Extension

An extension to OpenCL takes the form of a text document that describes
the changes to the specification.

Rationale:
> Using a separate document enables a lightweight process for authorship and
> review.  Describing all the changes in one easy-to-read text file allows all
> involved to focus on the collection of features rather than the mechanical
> details of integrating the changes into the main text.  Only the specification
> editors need to be concerned with those mechanical details.

The file name is the name of the extension followed by the `.asciidoc` suffix.
It is stored in the Khronos repository at
[https://github.com/KhronosGroup/OpenCL-Docs](https://github.com/KhronosGroup/OpenCL-Docs).
Successive revisions of an extension are stored as
successive `git` revisions of a single file.  The last section of
a document should also contain a summary of the revision history.

Rationale:
> It is important for reviewers to easily track incremental changes to an
> extension as it evolves.

When an extension is complete, the corresponding HTML document should be
published to the OpenCL Registry. The 'extensionshtml' target in
../Makefile will generate individual HTML documents in ../out/html/ for
each extension specification in this directory, as well as a document
containing all extensions in ../out/html/extensions.html.


## Extension Contents

The extension file content is UTF-8 text with Asciidoctor markup.  For
portability, use of non-ASCII characters is discouraged except where
essential, for example, for contributor names.

Use the native line endings style for your platform.
(The `git` repository is configured so that text documents are stored
with line endings encoded as linefeed-only, but they are written to
your local workspace in with native platform line endings.)

Rationale:
> Most OpenCL specifications use Asciidoctor markup. Using it for extensions
> reduces the work required to integrate them into the main
> specification, produces well-formatted output, and simplifies the process of
> authoring well-formatted output.  Also, asciidoctor is readable as plain text,
> and is easily diff-able with standard tools such as `git`.

## Token Registration

All new token values must be drawn from ranges registered in the
OpenCL Registry file before an extension can be considered complete.

For KHR extensions, individual token names and associated values must
be registered in the OpenCL Registry.

## Token Naming

Different token semantics require different names.  When a named enumerated
token might change semantics during the evolution of the extension from
vendor to EXT and finally to KHR, then the token name should use a corresponding
suffix.  For example CL_FOO_ENUM would be named CL_FOO_ENUM_EXT in an EXT
extension, and it would be named CL_FOO_ENUM_KHR in a KHR extension.

Naming summary:

* Default is to add a suffix on each new token.
* Normally all new tokens use the same suffix.
* If not expected to be ratified by Khronos, use an EXT or vendor suffix.
* If on track to be ratified by Khronos, use a KHR suffix.
* If on track to be ratified by Khronos, _and_ you fully expect the feature
  to eventually migrate to core with the same semantics, then no suffix
  is required.  This is a high bar, requiring working group agreement that
  the final semantics are already achieved.
* Aliasing:  If an extension evolves from a vendor extension to an EXT or
  a KHR or to the core spec without changing semantics then the spec can
  add an alias: a new name with a new suffix but denoting the same numeric
  value.
* Follow existing conventions.  For example, if introducing a new device
  query, the token name should start with CL_DEVICE.

# Revision History

* 2018-02-14: Initial version, modified for OpenCL.
