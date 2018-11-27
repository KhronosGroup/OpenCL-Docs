# Copyright (c) 2013-2018 The Khronos Group Inc.
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

# OpenCL Extension makefile
#
# Default target:
# - html
#
# Targets:
# - html: builds individual HTML extension specifications
# - pdf: builds individual PDF extension specifications
# - html_full: builds individual HTML extension specifications and
#       a combined HTML doc with all specifications
# - pdf_full: builds individual PDF extension specifications and
#       a combined PDF doc with all specifications
#

all: html

QUIET ?= @
ASCIIDOC ?= asciidoc.py
XMLLINT ?= xmllint
DBLATEX ?= dblatex
VERBOSE ?=

AD_HTML_OPTIONS = -b html5 -a icons -a toc2 -a toclevels=1
AD_DB_OPTIONS = -b docbook -f config/mathjax-docbook.conf -a a2xformat=pdf -a mathjax
DB_OPTIONS_COMBINED = -P doc.layout="coverpage toc frontmatter mainmatter" -p dblatex/asciidoc-dblatex-combined.xsl -s dblatex/asciidoc-dblatex-combined.sty 
DB_OPTIONS_INDIVIDUAL = -P doc.layout="frontmatter mainmatter" -p dblatex/asciidoc-dblatex-individual.xsl -s dblatex/asciidoc-dblatex-individual.sty

RM=rm -f
RMRF=rm -rf
MKDIR=mkdir -p
CP=cp
ECHO:=echo

# Target directories for output files
OUTDIR := .
HTMLDIR := $(OUTDIR)
PDFDIR := $(OUTDIR)

# Main (root) asciidoc spec source file
TOPDOC := extensions.txt
# Included extension documents
EXTENSIONS := $(wildcard [A-Za-z]*.asciidoc)
# All non-format-specific dependencies
COMMONDOCS := $(EXTENSIONS)

EXTENSIONS_HTML = $(patsubst %.asciidoc,$(HTMLDIR)/%.html,$(EXTENSIONS))
EXTENSIONS_XML = $(patsubst %.asciidoc,$(PDFDIR)/%.pdf.xml,$(EXTENSIONS))
EXTENSIONS_PDF = $(patsubst %.asciidoc,$(PDFDIR)/%.pdf,$(EXTENSIONS))

html: $(EXTENSIONS_HTML)
html_full: $(HTMLDIR)/extensions.html html
pdf: $(EXTENSIONS_PDF)
pdf_full: $(PDFDIR)/extensions.pdf pdf

$(HTMLDIR)/extensions.html: $(TOPDOC) $(COMMONDOCS)
	$(QUIET)if test ! -d $(HTMLDIR) ; then $(MKDIR) $(HTMLDIR) ; fi
	$(QUIET)$(ASCIIDOC) $(AD_HTML_OPTIONS) -o $@ $(TOPDOC)
	$(QUIET)dos2unix $@ 2> /dev/null

$(HTMLDIR)/%.html : %.asciidoc
	$(QUIET)if test ! -d $(HTMLDIR) ; then $(MKDIR) $(HTMLDIR) ; fi
	$(QUIET)$(ASCIIDOC) $(AD_HTML_OPTIONS) -o $@ $<
	$(QUIET)dos2unix $@ 2> /dev/null

$(PDFDIR)/extensions.pdf : $(TOPDOC) $(COMMONDOCS)
	$(QUIET)if test ! -d $(PDFDIR) ; then $(MKDIR) $(PDFDIR) ; fi
	$(QUIET)$(ASCIIDOC) $(AD_DB_OPTIONS) -o $@.xml $<
	$(QUIET)$(XMLLINT) --nonet --noout --valid $@.xml
	$(QUIET)$(DBLATEX) -t pdf ${DB_OPTIONS_COMBINED} -o $@ $@.xml
	$(QUIET)dos2unix $@ 2> /dev/null

$(PDFDIR)/%.pdf : %.asciidoc
	$(QUIET)if test ! -d $(PDFDIR) ; then $(MKDIR) $(PDFDIR) ; fi
	$(QUIET)$(ASCIIDOC) $(AD_DB_OPTIONS) $(VERBOSE) -o $@.xml $<
	$(QUIET)$(XMLLINT) --nonet --noout --valid $@.xml
	$(QUIET)$(DBLATEX) -t pdf ${DB_OPTIONS_INDIVIDUAL} $(VERBOSE) -o $@ $@.xml
	$(QUIET)dos2unix $@ 2> /dev/null

clean: clean_html clean_pdf

clean_html:
	$(QUIET)$(RM) $(EXTENSIONS_HTML) $(HTMLDIR)/extensions.html

clean_pdf:
	$(QUIET)$(RM) $(EXTENSIONS_XML) $(EXTENSIONS_PDF)
	$(QUIET)$(RM) $(PDFDIR)/extensions.pdf.xml $(PDFDIR)/extensions.pdf
