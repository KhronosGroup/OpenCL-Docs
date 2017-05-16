# Copyright (c) 2013-2017 The Khronos Group Inc.
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

QUIET ?=
ASCIIDOC ?= asciidoc
XMLLINT ?= xmllint
DBLATEX ?= dblatex
DOS2UNIX ?= dos2unix
RM ?= rm -f
VERBOSE ?=
SPECVERSION ?= specversion.txt
GITHEAD ?= ./.git/logs/HEAD

AD_HTML_OPTIONS = -b html5 -a toc2 -a toclevels=3 -a mathjax -f config/mathjax-asciidoc.conf
AD_DB_OPTIONS = -b docbook -a docinfo

all: api env ext

clean:
	$(QUIET)$(RM) $(SPECVERSION)
	$(QUIET)$(RM) OpenCL_API.html OpenCL_API-docinfo.xml OpenCL_API.xml OpenCL_API.pdf
	$(QUIET)$(RM) opencl_env.html opencl_env-docinfo.xml opencl_env.pdf.xml opencl_env.pdf
	$(QUIET)$(RM) opencl_ext.html opencl_ext-docinfo.xml opencl_ext.pdf.xml opencl_ext.pdf


ifeq ($(wildcard $(GITHEAD)),)
$(SPECVERSION):
	$(QUIET)echo ":revnumber: git information not available" > $@

OpenCL_API-docinfo.xml:
	$(QUIET)echo "<subtitle>unknown version</subtitle>" > $@

opencl_env-docinfo.xml:
	$(QUIET)echo "<subtitle>unknown version</subtitle>" > $@

opencl_ext-docinfo.xml:
	$(QUIET)echo "<subtitle>unknown version</subtitle>" > $@
else
$(SPECVERSION): $(GITHEAD)
	$(QUIET)echo ":revnumber: " `git describe --tags --dirty` > $@

OpenCL_API-docinfo.xml: $(GITHEAD)
	$(QUIET)echo "<subtitle>" `git describe --tags --dirty` "</subtitle>" > $@

opencl_env-docinfo.xml: $(GITHEAD)
	$(QUIET)echo "<subtitle>" `git describe --tags --dirty` "</subtitle>" > $@

opencl_ext-docinfo.xml: $(GITHEAD)
	$(QUIET)echo "<subtitle>" `git describe --tags --dirty` "</subtitle>" > $@
endif


OPENCL_API_ASC_DEPS=OpenCL_API.asc $(shell grep ^include:: OpenCL_API.asc | sed -e 's/^include:://' -e 's/\[\]/ /' | xargs echo)
DB_API_OPTIONS = -P doc.layout="coverpage toc mainmatter" -P doc.publisher.show=0 -P latex.output.revhistory=0 -p dblatex/asciidoc-dblatex.xsl -s dblatex/asciidoc-dblatex.sty

api: OpenCL_API.html OpenCL_API.pdf

OpenCL_API.html: $(OPENCL_API_ASC_DEPS)
	$(QUIET)$(ASCIIDOC) $(AD_HTML_OPTIONS) $(VERBOSE) -o $@ $<
	$(QUIET)$(DOS2UNIX) $@ 2> /dev/null

OpenCL_API.xml: $(OPENCL_API_ASC_DEPS) OpenCL_API-docinfo.xml
	$(QUIET)$(ASCIIDOC) $(AD_DB_OPTIONS) $(VERBOSE) -o $@ $<
	$(QUIET)$(XMLLINT) --nonet --noout --valid $@

OpenCL_API.pdf: OpenCL_API.xml
	$(QUIET)$(DBLATEX) -t pdf $(DB_API_OPTIONS) $(VERBOSE) -o $@ $<
	$(QUIET)$(DOS2UNIX) $@ 2> /dev/null


OPENCL_ENV_ASC_DEPS=opencl_env.asc $(shell grep ^include:: opencl_env.asc | sed -e 's/^include:://' -e 's/\[\]/ /' | xargs echo)
DB_ENV_OPTIONS = -P doc.layout="coverpage toc mainmatter" -P doc.publisher.show=0 -P latex.output.revhistory=0 -p env/dblatex/asciidoc-dblatex.xsl -s env/dblatex/asciidoc-dblatex.sty 

env: opencl_env.html opencl_env.pdf

opencl_env.html: $(OPENCL_ENV_ASC_DEPS)
	$(QUIET)$(ASCIIDOC) $(AD_HTML_OPTIONS) $(VERBOSE) -o $@ $<
	$(QUIET)$(DOS2UNIX) $@ 2> /dev/null

opencl_env.pdf: $(OPENCL_ENV_ASC_DEPS) opencl_env-docinfo.xml
	$(QUIET)$(ASCIIDOC) $(AD_DB_OPTIONS) $(VERBOSE) -o $@.xml $<
	$(QUIET)$(XMLLINT) --nonet --noout --valid $@.xml
	$(QUIET)$(DBLATEX) -t pdf $(DB_ENV_OPTIONS) $(VERBOSE) -o $@ $@.xml
	$(QUIET)$(DOS2UNIX) $@ 2> /dev/null


AD_EXT_HTML_OPTIONS = -b html5 -a toc2 -a toclevels=2 -a mathjax -f config/mathjax-asciidoc.conf
OPENCL_EXT_ASC_DEPS=opencl_ext.asc $(shell grep ^include:: opencl_ext.asc | sed -e 's/^include:://' -e 's/\[\]/ /' | xargs echo)
DB_EXT_OPTIONS = -P doc.layout="coverpage toc mainmatter index" -P doc.publisher.show=0 -P latex.output.revhistory=0 -p ext/dblatex/asciidoc-dblatex.xsl -s ext/dblatex/asciidoc-dblatex.sty 

ext: opencl_ext.html opencl_ext.pdf

opencl_ext.html: $(OPENCL_EXT_ASC_DEPS)
	$(QUIET)$(ASCIIDOC) $(AD_EXT_HTML_OPTIONS) $(VERBOSE) -o $@ $<
	$(QUIET)$(DOS2UNIX) $@ 2> /dev/null

opencl_ext.pdf: $(OPENCL_EXT_ASC_DEPS) opencl_ext-docinfo.xml
	$(QUIET)$(ASCIIDOC) $(AD_DB_OPTIONS) $(VERBOSE) -o $@.xml $<
	$(QUIET)$(XMLLINT) --nonet --noout --valid $@.xml
	$(QUIET)$(DBLATEX) -t pdf $(DB_EXT_OPTIONS) $(VERBOSE) -o $@ $@.xml
	$(QUIET)$(DOS2UNIX) $@ 2> /dev/null
