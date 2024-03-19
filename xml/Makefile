# Copyright (c) 2013-2024 The Khronos Group Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# If a recipe fails, delete its target file. Without this cleanup, the leftover
# file from the failed recipe can falsely satisfy dependencies on subsequent
# runs of `make`.
.DELETE_ON_ERROR:

# Generator scripts and options
# GENOPTS can be e.g. '-noprotect'

PYTHON ?= python3
PYFILES = genheaders.py reg.py
GENOPTS =

# Generate API headers from XML. Many other files can be generated
# from XML using the scripts, but they are all generated in ../ as
# part of the process of building the Specification.
# (generated headers are not supported yet)
#
# Targets:
#
# default / install - regenerate headers
# validate - run XML validator against the schema.
# clean_dirt - remove intermediate files.
# clean - remove installed and intermediate files.

INCLUDE     = ../include
CLHEADER    = $(INCLUDE)/CL
SRC	    = ../src

# Vulkan platform-specific headers
PLATFORM_HEADERS =
HEADERS     = $(CLHEADER)/cl.h $(PLATFORM_HEADERS)

default install: $(HEADERS)

################################################

# Autogenerate headers from XML API description

# Python and XML files on which headers depends
HEADER_DEPENDS = cl.xml gencl.py reg.py generator.py

$(HEADERS): $(HEADER_DEPENDS)
	$(PYTHON) gencl.py -registry cl.xml -o $(CLHEADER) $(notdir $@)

platform: $(PLATFORM_HEADERS)

# Verify registry XML file against the schema
validate:
	jing -c registry.rnc cl.xml

################################################

# Files to clean up
PYDIRT = diag.txt dumpReg.txt errwarn.txt *.pyc regdump.txt
DIRT = $(PYDIRT) ERRS \#*

# Clean intermediate files
clean_dirt:
	-rm -f $(DIRT)

# Clean generated targets as well as intermediates.
clean clobber: clean_dirt
	-rm -f $(HEADERS) $(PLATFORM_HEADERS)
