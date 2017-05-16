# OpenCL API

## Overview

This repository contains the source and tool chain used to generate the formal OpenCL API, OpenCL Extensions, and OpenCL SPIR-V Environment specifications.

## Source Code

The OpenCL specifications are maintained by members of the The Khronos Group Inc.,
at https://github.com/KhronosGroup/OpenCL-Docs.

Contributions via merge request are welcome. Changes must be provided under the [Apache 2.0](#license).  You'll be prompted with a one-time "click-through" Contributor's License Agreement (CLA) dialog as part of submitting your pull request or other contribution to GitHub.

We intend to maintain a linear history on the GitHub `master` branch.

## Repository Structure
```
README.md               This file
Makefile                Used to build the HTML and PDF spec artifacts
OpenCL_API.asc          Main source file for the OpenCL API spec
opencl_env.asc          Main source file for the OpenCL SPIR-V Environment spec
opencl_ext.asc          Main source file for the OpenCL Extensions spec
config/                 MathJax files
dblatex/                DocBook files for the OpenCL API spec
env/                    Supporting files for the OpenCL SPIR-V Environment spec
    dblatex/            DocBook files for the OpenCL SPIR-V Environment spec
ext/                    Supporting files for the OpenCL Extension spec
    dblatex/            DocBook files for the OpenCL Extension spec
images/                 Shared images, used by all specs
opencl22-API_files/     Images used by the OpenCL API spec
```

## Build

The project uses a Makefile to build the HTML and PDF versions of all specifications, so to build the specifications you must have a GNU-compatible `make`.

The OpenCL specifications are currently authored using [AsciiDoc][asciidoc] markup, so you must have a version of `asciidoc`.

On some systems, you may also need:

* `dblatex`
* `docbook`
* `source-highlight`

If you have installed all build dependencies, you should be able to build the OpenCL specifications by simply running:

```sh
make
```

The OpenCL specifications have been built on Linux and on Microsoft Windows (via [Cygwin][cygwin])).  Other platforms may work as well.

## License
<a name="license"></a>
Full license terms are in [LICENSE](LICENSE).
```
Copyright (c) 2015-2017 The Khronos Group Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

OpenCL and the OpenCL logo are trademarks of Apple Inc. used by permission by Khronos.

[asciidoc]: http://asciidoc.org
[cygwin]: https://www.cygwin.com
