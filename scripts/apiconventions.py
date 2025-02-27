#!/usr/bin/python3 -i
#
# Copyright 2021-2024 The Khronos Group Inc.
# SPDX-License-Identifier: Apache-2.0

# Generic alias for working group-specific API conventions interface.

# This import should be changed at the repository / working group level to
# specify the correct API's conventions.

defaultAPI = 'opencl'

from clconventions import OpenCLConventions as APIConventions
