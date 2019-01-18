# Copyright (c) 2013-2019 The Khronos Group Inc.
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
#	a combined HTML doc with all specifications
# - pdf_full: builds individual PDF extension specifications and
#	a combined PDF doc with all specifications

QUIET	    ?=
ASCIIDOCTOR ?= asciidoctor
RM	    = rm -f
RMRF	    = rm -rf
MKDIR	    = mkdir -p
CP	    = cp
GS_EXISTS   := $(shell command -v gs 2> /dev/null)
GITHEAD     = ./.git/logs/HEAD

# Target directories for output files
# HTMLDIR - 'html' target
# PDFDIR - 'pdf' target
# CHECKDIR - 'allchecks' target
OUTDIR	  := ../out
HTMLDIR   := $(OUTDIR)/html
PDFDIR	  := $(OUTDIR)/pdf

# PDF Equations are written to SVGs, this dictates the location to store those files (temporary)
PDFMATHDIR := $(OUTDIR)/equations_temp

# Set VERBOSE to -v to see what asciidoc is doing.
VERBOSE =

# asciidoc attributes to set.
# NOTEOPTS   sets options controlling which NOTEs are generated
# ATTRIBOPTS sets the api revision and enables MathJax generation
# ADOCOPTS   options for asciidoc->HTML5 output
# Currently unused in CL spec
NOTEOPTS     = -a editing-notes
# Spell out RFC2822 format as not all date commands support -R
SPECDATE     = $(shell echo `date -u "+%a, %d %b %Y %T %z"`)

# Generate Asciidoc attributes for spec version and remark
# The dependency on HEAD is per the suggestion in
# http://neugierig.org/software/blog/2014/11/binary-revisions.html
ifeq ($(wildcard $(GITHEAD)),)
# If GITHEAD does not exist, don't include branch info.
SPECREVISION = Git tag information not available
SPECREMARK = Git branch information not available
else
# Expect the tag to be in the format MAJOR.MINOR-REVISION, e.g. 2.2-9.
# If your current commit is not a tag then a commit hash will be appended.
# If you have locally modified files then -dirty will be appended.
# Could use `git log -1 --format="%cd"` to get branch commit date
SPECREVISION = $(shell echo `git describe --tags --dirty`)
# This used to be a dependency in the spec html/pdf targets,
# but that's likely to lead to merge conflicts. Just regenerate
# when pushing a new spec for review to the sandbox.
SPECREMARK = from git branch: $(shell echo `git symbolic-ref --short HEAD`) \
	     commit: $(shell echo `git log -1 --format="%H"`)
endif

ATTRIBOPTS   = -a revnumber="$(SPECREVISION)" \
	       -a revdate="$(SPECDATE)" \
	       -a revremark="$(SPECREMARK)" \
	       -a stem=latexmath

# Currently not using custom asciidoctor macros
# ADOCEXTS     = -r $(CURDIR)/../config/vulkan-macros.rb
ADOCEXTS     = -r $(CURDIR)/../config/sectnumoffset-treeprocessor.rb
ADOCOPTS     = -d book $(ATTRIBOPTS) $(NOTEOPTS) $(VERBOSE) $(ADOCEXTS)

KATEXDIR     = ../katex
ADOCHTMLEXTS = -r $(CURDIR)/../config/katex_replace.rb
ADOCHTMLOPTS = $(ADOCHTMLEXTS) -a stylesheet=khronos.css \
	       -a stylesdir=../config -a katexpath=$(KATEXDIR)

# The monkey patch for asciidoctor-pdf fixes issue #259
# (https://github.com/asciidoctor/asciidoctor-pdf/issues/259).
# I've submitted a pull request to fix it, once it goes into a gem release, we'll remove this.
ADOCPDFEXTS  = -r asciidoctor-pdf -r asciidoctor-mathematical \
	       -r $(CURDIR)/../config/asciidoctor-pdf-monkeypatch.rb --trace
ADOCPDFOPTS  = $(ADOCPDFEXTS) -a mathematical-format=svg \
	       -a imagesoutdir=$(PDFMATHDIR)

.PHONY: directories

# Included extension documents
EXTENSIONS := $(wildcard [A-Za-z]*.asciidoc)
EXTENSIONS_HTML = $(patsubst %.asciidoc,$(HTMLDIR)/%.html,$(EXTENSIONS))
EXTENSIONS_PDF = $(patsubst %.asciidoc,$(PDFDIR)/%.pdf,$(EXTENSIONS))

all: html

ext: exthtml extpdf

html: $(EXTENSIONS_HTML)

html_full: exthtml html

pdf: $(EXTENSIONS_PDF)

pdf_full: extpdf pdf

# README.md is a proxy for all the katex files that need to be installed
katexinst: $(OUTDIR)/katex/README.md

$(OUTDIR)/katex/README.md: ../katex/README.md
	$(QUIET)$(MKDIR) $(OUTDIR)
	$(QUIET)$(RMRF)  $(OUTDIR)/katex
	$(QUIET)$(CP) -rf ../katex $(OUTDIR)

# Combined extension spec

# Top-level spec source file
EXTSPEC = extensions
EXTSRC = $(EXTSPEC).txt \
    $(shell grep ^include:: $(EXTSPEC).txt | sed -e 's/^include:://' -e 's/\[\]/ /' | xargs echo)
EXTSPECSRC = $(EXTSPEC).txt $(EXTSRC)

exthtml: $(HTMLDIR)/$(EXTSPEC).html $(EXTSPECSRC)

$(HTMLDIR)/$(EXTSPEC).html: $(EXTSPECSRC) katexinst
	$(QUIET)$(ASCIIDOCTOR) -b html5 $(ADOCOPTS) $(ADOCHTMLOPTS) -o $@ $(EXTSPEC).txt

extpdf: $(PDFDIR)/$(EXTSPEC).pdf $(EXTSPECSRC)

$(PDFDIR)/$(EXTSPEC).pdf: $(EXTSPECSRC)
	$(QUIET)$(MKDIR) $(PDFDIR)
	$(QUIET)$(MKDIR) $(PDFMATHDIR)
	$(QUIET)$(ASCIIDOCTOR) -b pdf $(ADOCOPTS) $(ADOCPDFOPTS) -o $@ $(EXTSPEC).txt
ifndef GS_EXISTS
	$(QUIET) echo "Warning: Ghostscript not installed, skipping pdf optimization"
else
	$(QUIET)$(CURDIR)/../config/optimize-pdf $@
	$(QUIET)rm $@
	$(QUIET)mv $(PDFDIR)/$(EXTSPEC)-optimized.pdf $@
endif

# Generic targets for individual extension specs
$(HTMLDIR)/%.html : %.asciidoc
	$(QUIET)$(ASCIIDOCTOR) -b html5 $(ADOCOPTS) $(ADOCHTMLOPTS) -o $@ $<

$(PDFDIR)/%.pdf : %.asciidoc
	$(QUIET)$(MKDIR) $(PDFDIR)
	$(QUIET)$(MKDIR) $(PDFMATHDIR)
	$(QUIET)$(ASCIIDOCTOR) -b pdf $(ADOCOPTS) $(ADOCPDFOPTS) -o $@ $<
ifndef GS_EXISTS
	$(QUIET) echo "Warning: Ghostscript not installed, skipping pdf optimization"
else
	$(QUIET)$(CURDIR)/../config/optimize-pdf $@
	$(QUIET)rm $@
	$(QUIET)mv $(basename $@)-optimized.pdf $@
endif

# Clean generated and output files

clean: clean_html clean_pdf

clean_html:
	$(QUIET)$(RMRF) $(HTMLDIR) $(OUTDIR)/katex

clean_pdf:
	$(QUIET)$(RMRF) $(PDFDIR) $(PDFMATHDIR)
