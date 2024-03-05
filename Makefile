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

QUIET	    ?=
ASCIIDOCTOR ?= asciidoctor
XMLLINT     ?= xmllint
DBLATEX     ?= dblatex
DOS2UNIX    ?= dos2unix
RM	    = rm -f
RMRF	    = rm -rf
MKDIR	    = mkdir -p
CP	    = cp
GITHEAD     = ./.git/logs/HEAD

# Target directories for output files
# HTMLDIR - 'html' target
# PDFDIR - 'pdf' target
# CHECKDIR - 'allchecks' target
OUTDIR	  := out
HTMLDIR   := $(OUTDIR)/html
PDFDIR	  := $(OUTDIR)/pdf

# PDF Equations are written to SVGs, this dictates the location to store those files (temporary)
PDFMATHDIR := $(OUTDIR)/equations_temp

# Set VERBOSE to -v to see what asciidoc is doing.
VERBOSE =

# asciidoc attributes to set.
# NOTEOPTS   sets options controlling which NOTEs are generated
# ATTRIBOPTS sets the api revision and enables MathJax generation, and
#	     the path to generate include files
# ADOCOPTS   options for asciidoc->HTML5 output (book document type)
# ADOCMANOPTS options for asciidoc->HTML5 output (manpage document type)
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
# The C++ for OpenCL document revision scheme is aligned with its release date.
# Revision naming scheme is as follows:
# DocRevYYYY.MM,
# where YYYY corresponds to its release year,
# MM corresponds to its release month.
# Example for the release in Dec 2021 the revision is DocRev2021.12.
# Leave as 'DocRevYYYY.MM-Next' if the doc content does not correspond to any official revision.
# where DocRevYYYY.MM is the last released revision.
CXX4OPENCL_DOCREVISION = DocRev2021.12
CXX4OPENCL_DOCREMARK = $(SPECREMARK) \
			tag: $(SPECREVISION)

COMMONATTRIBOPTS	= -a revdate="$(SPECDATE)" \
			  -a stem=latexmath \
			  -a generated=$(GENERATED) \
			  -a sectnumlevels=5

ATTRIBOPTS   = -a revnumber="$(SPECREVISION)" \
	       -a revremark="$(SPECREMARK)" \
	       $(COMMONATTRIBOPTS)

CXX4OPENCL_ATTRIBOPTS   = -a revnumber="$(CXX4OPENCL_DOCREVISION)" \
			  -a revremark="$(CXX4OPENCL_DOCREMARK)" \
			  $(COMMONATTRIBOPTS)


ADOCEXTS	      = -r $(CURDIR)/config/sectnumoffset-treeprocessor.rb \
	-r $(CURDIR)/config/spec-macros.rb \
	-r $(CURDIR)/config/rouge_opencl.rb
CXX4OPENCL_ADOCOPTS   = -d book $(CXX4OPENCL_ATTRIBOPTS) $(NOTEOPTS) $(VERBOSE) $(ADOCEXTS)
ADOCCOMMONOPTS	      = -a apispec="$(CURDIR)/api" \
			-a config="$(CURDIR)/config" \
			-a cspec="$(CURDIR)/c" \
			-a images="$(CURDIR)/images" \
			$(ATTRIBOPTS) $(NOTEOPTS) $(VERBOSE) $(ADOCEXTS)
ADOCOPTS	      = -d book $(ADOCCOMMONOPTS)
ADOCMANOPTS	      = -d manpage $(ADOCCOMMONOPTS)

# ADOCHTMLOPTS relies on the relative runtime path from the output HTML
# file to the katex scripts being set with KATEXDIR. This is overridden
# by some targets.
# ADOCHTMLOPTS also relies on the absolute build-time path to the
# 'stylesdir' containing our custom CSS.
KATEXDIR     = ../katex
ADOCHTMLEXTS = -r $(CURDIR)/config/katex_replace.rb
ADOCHTMLOPTS = $(ADOCHTMLEXTS) -a katexpath=$(KATEXDIR) \
	       -a stylesheet=khronos.css -a stylesdir=$(CURDIR)/config \
	       -a sectanchors

ADOCPDFEXTS  = -r asciidoctor-pdf -r asciidoctor-mathematical --trace
ADOCPDFOPTS  = $(ADOCPDFEXTS) -a mathematical-format=svg \
	       -a imagesoutdir=$(PDFMATHDIR)

# Where to put dynamically generated dependencies of the spec and other
# targets, from API XML. GENERATED and APIINCDIR specify the location of
# the API interface includes.
# GENDEPENDS could have multiple dependencies.
GENERATED  = $(CURDIR)/generated
REFPATH    = $(GENERATED)/refpage
APIINCDIR  = $(GENERATED)/api
VERSIONDIR = $(APIINCDIR)/version-notes
GENDEPENDS = $(APIINCDIR)/timeMarker

.PHONY: directories

# README.md is a proxy for all the katex files that need to be installed
KATEXINST = $(OUTDIR)/katex/README.md

$(OUTDIR)/katex/README.md: katex/README.md
	$(QUIET)$(MKDIR) $(OUTDIR)
	$(QUIET)$(RMRF)  $(OUTDIR)/katex
	$(QUIET)$(CP) -rf katex $(OUTDIR)

all: api env ext extensions cxx c icdinst

allman: manhtmlpages

api: apihtml apipdf

env: envhtml envpdf

ext: exthtml extpdf

extensions: extensionshtml extensionspdf

cxx: cxxhtml cxxpdf

cxx4opencl: cxx4openclhtml cxx4openclpdf

c: chtml cpdf

icdinst: icdinsthtml icdinstpdf

html: apihtml envhtml exthtml extensionshtml cxxhtml chtml icdinsthtml

# PDF optimizer - usage $(OPTIMIZEPDF) in.pdf out.pdf
# OPTIMIZEPDFOPTS=--compress-pages is slightly better, but much slower
OPTIMIZEPDF = hexapdf optimize $(OPTIMIZEPDFOPTS)

pdf: apipdf envpdf extpdf extensionspdf cxxpdf cpdf icdinstpdf

# Spec targets.
# There is some complexity to try and avoid short virtual targets like
# 'html' causing specs to *always* be regenerated.

src:
	@echo APISPECSRC = $(APISPECSRC)
	@echo ENVSPECSRC = $(ENVSPECSRC)
	@echo EXTSPECSRC = $(EXTSPECSRC)

# API spec

# Top-level spec source file
APISPEC = OpenCL_API
APISPECSRC = $(APISPEC).txt $(GENDEPENDS) \
    $(shell grep ^include:: $(APISPEC).txt | sed -e 's/^include:://' -e 's/\[\]/ /' | xargs echo)

apihtml: $(HTMLDIR)/$(APISPEC).html $(APISPECSRC)

$(HTMLDIR)/$(APISPEC).html: $(APISPECSRC) $(KATEXINST)
	$(QUIET)$(ASCIIDOCTOR) -b html5 $(ADOCOPTS) $(ADOCHTMLOPTS) -o $@ $(APISPEC).txt

apipdf: $(PDFDIR)/$(APISPEC).pdf $(APISPECSRC)

$(PDFDIR)/$(APISPEC).pdf: $(APISPECSRC)
	$(QUIET)$(MKDIR) $(PDFDIR)
	$(QUIET)$(MKDIR) $(PDFMATHDIR)
	$(QUIET)$(ASCIIDOCTOR) -b pdf $(ADOCOPTS) $(ADOCPDFOPTS) -o $@ $(APISPEC).txt
	$(QUIET)$(OPTIMIZEPDF) $@ $@.out.pdf && mv $@.out.pdf $@

# Environment spec

# Top-level spec source file
ENVSPEC = OpenCL_Env
ENVSPECSRC = $(ENVSPEC).txt $(GENDEPENDS) \
    $(shell grep ^include:: $(ENVSPEC).txt | sed -e 's/^include:://' -e 's/\[\]/ /' | xargs echo)

envhtml: $(HTMLDIR)/$(ENVSPEC).html $(ENVSPECSRC)

$(HTMLDIR)/$(ENVSPEC).html: $(ENVSPECSRC) $(KATEXINST)
	$(QUIET)$(ASCIIDOCTOR) -b html5 $(ADOCOPTS) $(ADOCHTMLOPTS) -o $@ $(ENVSPEC).txt

envpdf: $(PDFDIR)/$(ENVSPEC).pdf $(ENVSPECSRC)

$(PDFDIR)/$(ENVSPEC).pdf: $(ENVSPECSRC)
	$(QUIET)$(MKDIR) $(PDFDIR)
	$(QUIET)$(MKDIR) $(PDFMATHDIR)
	$(QUIET)$(ASCIIDOCTOR) -b pdf $(ADOCOPTS) $(ADOCPDFOPTS) -o $@ $(ENVSPEC).txt
	$(QUIET)$(OPTIMIZEPDF) $@ $@.out.pdf && mv $@.out.pdf $@

# Extensions spec
EXTSPEC = OpenCL_Ext
EXTSPECSRC = $(EXTSPEC).txt $(GENDEPENDS) \
    $(shell grep ^include:: $(EXTSPEC).txt | sed -e 's/^include:://' -e 's/\[\]/ /' | xargs echo)

exthtml: $(HTMLDIR)/$(EXTSPEC).html $(EXTSPECSRC)

$(HTMLDIR)/$(EXTSPEC).html: $(EXTSPECSRC) $(KATEXINST)
	$(QUIET)$(ASCIIDOCTOR) -b html5 $(ADOCOPTS) $(ADOCHTMLOPTS) -o $@ $(EXTSPEC).txt

extpdf: $(PDFDIR)/$(EXTSPEC).pdf $(EXTSPECSRC)

$(PDFDIR)/$(EXTSPEC).pdf: $(EXTSPECSRC)
	$(QUIET)$(MKDIR) $(PDFDIR)
	$(QUIET)$(MKDIR) $(PDFMATHDIR)
	$(QUIET)$(ASCIIDOCTOR) -b pdf $(ADOCOPTS) $(ADOCPDFOPTS) -o $@ $(EXTSPEC).txt
	$(QUIET)$(OPTIMIZEPDF) $@ $@.out.pdf && mv $@.out.pdf $@

# Individual extensions spec(s)
EXTDIR = extensions
EXTENSIONSSPEC = extensions
EXTENSIONSSPECSRC = $(EXTDIR)/$(EXTENSIONSSPEC).txt ${GENDEPENDS} \
    $(shell grep ^include:: $(EXTDIR)/$(EXTENSIONSSPEC).txt | sed -e 's/^include:://' -e 's/\[\]/ /' | xargs echo)

# Included extension documents
EXTENSIONS := $(notdir $(wildcard $(EXTDIR)/[A-Za-z]*.asciidoc))
EXTENSIONS_HTML = $(patsubst %.asciidoc,$(HTMLDIR)/%.html,$(EXTENSIONS))
EXTENSIONS_PDF = $(patsubst %.asciidoc,$(PDFDIR)/%.pdf,$(EXTENSIONS))

extensionshtml: $(HTMLDIR)/$(EXTENSIONSSPEC).html $(EXTENSIONSSPECSRC) $(EXTENSIONS_HTML)

$(HTMLDIR)/$(EXTENSIONSSPEC).html: $(EXTENSIONSSPECSRC) $(KATEXINST)
	$(QUIET)$(ASCIIDOCTOR) -b html5 $(ADOCOPTS) $(ADOCHTMLOPTS) -o $@ $(EXTDIR)/$(EXTENSIONSSPEC).txt

# I don't know why the pattern rule below requires vpath be overridden
# to point to the extensions/ directory, since the rule itself already
# points there.
vpath %.asciidoc $(EXTDIR)

$(HTMLDIR)/%.html: $(EXTDIR)/%.asciidoc $(GENDEPENDS)
	$(QUIET)$(ASCIIDOCTOR) -b html5 $(ADOCOPTS) $(ADOCHTMLOPTS) -o $@ $<

extensionspdf: $(PDFDIR)/$(EXTENSIONSSPEC).pdf $(EXTENSIONSSPECSRC)

$(PDFDIR)/$(EXTENSIONSSPEC).pdf: $(EXTENSIONSSPECSRC) $(GENDEPENDS)
	$(QUIET)$(MKDIR) $(PDFDIR)
	$(QUIET)$(MKDIR) $(PDFMATHDIR)
	$(QUIET)$(ASCIIDOCTOR) -b pdf $(ADOCOPTS) $(ADOCPDFOPTS) -o $@ $(EXTDIR)/$(EXTENSIONSSPEC).txt
	$(QUIET)$(OPTIMIZEPDF) $@ $@.out.pdf && mv $@.out.pdf $@

# Language Extensions spec
CEXTDOC = OpenCL_LangExt
CEXTDOCSRC = $(CEXTDOC).txt $(GENDEPENDS) \
    $(shell grep ^include:: $(CEXTDOC).txt | sed -e 's/^include:://' -e 's/\[\]/ /' | xargs echo)

cexthtml: $(HTMLDIR)/$(CEXTDOC).html $(CEXTDOCSRC)

$(HTMLDIR)/$(CEXTDOC).html: $(CEXTDOCSRC) $(KATEXINST)
	$(QUIET)$(ASCIIDOCTOR) -b html5 $(ADOCOPTS) $(ADOCHTMLOPTS) -o $@ $(CEXTDOC).txt

cextpdf: $(PDFDIR)/$(CEXTDOC).pdf $(CEXTDOCSRC)

$(PDFDIR)/$(CEXTDOC).pdf: $(CEXTDOCSRC)
	$(QUIET)$(MKDIR) $(PDFDIR)
	$(QUIET)$(MKDIR) $(PDFMATHDIR)
	$(QUIET)$(ASCIIDOCTOR) -b pdf $(ADOCOPTS) $(ADOCPDFOPTS) -o $@ $(CEXTDOC).txt
	$(QUIET)$(OPTIMIZEPDF) $@ $@.out.pdf && mv $@.out.pdf $@

# C++ (cxx) spec
CXXSPEC = OpenCL_Cxx
CXXSPECSRC = $(CXXSPEC).txt $(GENDEPENDS) \
    $(shell grep ^include:: $(CXXSPEC).txt | sed -e 's/^include:://' -e 's/\[\]/ /' | xargs echo)

cxxhtml: $(HTMLDIR)/$(CXXSPEC).html $(CXXSPECSRC)

$(HTMLDIR)/$(CXXSPEC).html: $(CXXSPECSRC) $(KATEXINST)
	$(QUIET)$(ASCIIDOCTOR) -b html5 $(ADOCOPTS) $(ADOCHTMLOPTS) -o $@ $(CXXSPEC).txt

cxxpdf: $(PDFDIR)/$(CXXSPEC).pdf $(CXXSPECSRC)

$(PDFDIR)/$(CXXSPEC).pdf: $(CXXSPECSRC)
	$(QUIET)$(MKDIR) $(PDFDIR)
	$(QUIET)$(MKDIR) $(PDFMATHDIR)
	$(QUIET)$(ASCIIDOCTOR) -b pdf $(ADOCOPTS) $(ADOCPDFOPTS) -o $@ $(CXXSPEC).txt
	$(QUIET)$(OPTIMIZEPDF) $@ $@.out.pdf && mv $@.out.pdf $@

# C spec
CSPEC = OpenCL_C
CSPECSRC = $(CSPEC).txt $(GENDEPENDS) \
    $(shell grep ^include:: $(CSPEC).txt | sed -e 's/^include:://' -e 's/\[\]/ /' | xargs echo)

chtml: $(HTMLDIR)/$(CSPEC).html $(CSPECSRC)

$(HTMLDIR)/$(CSPEC).html: $(CSPECSRC) $(KATEXINST)
	$(QUIET)$(ASCIIDOCTOR) -b html5 $(ADOCOPTS) $(ADOCHTMLOPTS) -o $@ $(CSPEC).txt

cpdf: $(PDFDIR)/$(CSPEC).pdf $(CSPECSRC)

$(PDFDIR)/$(CSPEC).pdf: $(CSPECSRC)
	$(QUIET)$(MKDIR) $(PDFDIR)
	$(QUIET)$(MKDIR) $(PDFMATHDIR)
	$(QUIET)$(ASCIIDOCTOR) -b pdf $(ADOCOPTS) $(ADOCPDFOPTS) -o $@ $(CSPEC).txt
	$(QUIET)$(OPTIMIZEPDF) $@ $@.out.pdf && mv $@.out.pdf $@

# C++ for OpenCL doc
CXX4OPENCLDOC = CXX_for_OpenCL
CXX4OPENCLDOCSRC = $(CXX4OPENCLDOC).txt $(GENDEPENDS) \
    $(shell grep ^include:: $(CXX4OPENCLDOC).txt | sed -e 's/^include:://' -e 's/\[\]/ /' | xargs echo)

cxx4openclhtml: $(HTMLDIR)/$(CXX4OPENCLDOC).html $(CXX4OPENCLDOCSRC)

$(HTMLDIR)/$(CXX4OPENCLDOC).html: $(CXX4OPENCLDOCSRC) $(KATEXINST)
	$(QUIET)$(ASCIIDOCTOR) -b html5 $(CXX4OPENCL_ADOCOPTS) $(ADOCHTMLOPTS) -o $@ $(CXX4OPENCLDOC).txt

cxx4openclpdf: $(PDFDIR)/$(CXX4OPENCLDOC).pdf $(CXX4OPENCLDOCSRC)

$(PDFDIR)/$(CXX4OPENCLDOC).pdf: $(CXX4OPENCLDOCSRC)
	$(QUIET)$(MKDIR) $(PDFDIR)
	$(QUIET)$(MKDIR) $(PDFMATHDIR)
	$(QUIET)$(ASCIIDOCTOR) -b pdf $(CXX4OPENCL_ADOCOPTS) $(ADOCPDFOPTS) -o $@ $(CXX4OPENCLDOC).txt
	$(QUIET)$(OPTIMIZEPDF) $@ $@.out.pdf && mv $@.out.pdf $@

# ICD installation guidelines
ICDINSTSPEC = OpenCL_ICD_Installation
ICDINSTSPECSRC = $(ICDINSTSPEC).txt \
    $(shell grep ^include:: $(ICDINSTSPEC).txt | sed -e 's/^include:://' -e 's/\[\]/ /' | xargs echo)

icdinsthtml: $(HTMLDIR)/$(ICDINSTSPEC).html $(ICDINSTSPECSRC)

$(HTMLDIR)/$(ICDINSTSPEC).html: $(ICDINSTSPECSRC) $(KATEXINST)
	$(QUIET)$(ASCIIDOCTOR) -b html5 $(ADOCOPTS) $(ADOCHTMLOPTS) -o $@ $(ICDINSTSPEC).txt

icdinstpdf: $(PDFDIR)/$(ICDINSTSPEC).pdf $(ICDINSTSPECSRC)

$(PDFDIR)/$(ICDINSTSPEC).pdf: $(ICDINSTSPECSRC)
	$(QUIET)$(MKDIR) $(PDFDIR)
	$(QUIET)$(MKDIR) $(PDFMATHDIR)
	$(QUIET)$(ASCIIDOCTOR) -b pdf $(ADOCOPTS) $(ADOCPDFOPTS) -o $@ $(ICDINSTSPEC).txt
	$(QUIET)$(OPTIMIZEPDF) $@ $@.out.pdf && mv $@.out.pdf $@

# Clean generated and output files

clean: clean_html clean_pdf clean_generated

clean_html:
	$(QUIET)$(RMRF) $(HTMLDIR) $(MANHTMLDIR) $(OUTDIR)/katex

clean_pdf:
	$(QUIET)$(RMRF) $(PDFDIR) $(PDFMATHDIR)

clean_generated:
	$(QUIET)$(RMRF) $(APIINCDIR)/* $(GENERATED)/api.py $($(REFPATH)/
	$(QUIET)$(RMRF) $(PDFMATHDIR)
	$(QUIET)$(RMRF) $(GENERATED)/__pycache__

# Ref page targets for individual pages
MANDIR	    := man
MANSECTION  := 3

# These lists should be autogenerated

# Ref page sources for all CL interfaces
# Most are autogenerated; man/static/*.txt are hand-coded at present

# MANSOURCES is the list of individual refpage sources, excluding the
# single-page index, boilerplate document footer, and include files.
# For now, always build all refpages.
MANSOURCES   = $(filter-out $(REFPATH)/apispec.txt $(REFPATH)/footer.txt $(wildcard $(REFPATH)/*Inc.txt), $(wildcard $(REFPATH)/*.txt))

# Generation of ref page asciidoctor sources by extraction from the
# specification(s).
#
# Should have a proper dependency causing the man page sources to be
# generated by running genRef.py (once), but adding $(MANSOURCES) to the
# targets causes genRef.py to run once/target.
#
# Should pass in $(EXTOPTIONS) to determine which pages to generate.
# For now, all core and extension ref pages are extracted by genRef.py.
## Temporary - eventually should be all spec asciidoctor source files
SPECFILES = $(wildcard api/*.asciidoc) OpenCL_API.txt OpenCL_C.txt
SCRIPTS = scripts
GENREF = $(SCRIPTS)/genRef.py
LOGFILE = $(REFPATH)/refpage.log

refpages: $(REFPATH)/apispec.txt
$(REFPATH)/apispec.txt: $(SPECFILES) $(GENREF) $(SCRIPTS)/reflib.py $(GENERATED)/api.py
	$(QUIET)$(MKDIR) $(REFPATH)
	$(PYTHON) $(GENREF) -genpath $(GENERATED) -basedir $(REFPATH) \
	    -rewrite $(REFPATH)/rewritebody -toc $(REFPATH)/tocbody \
	    -log $(LOGFILE) $(SPECFILES)
	cat $(MANDIR)/tochead $(REFPATH)/tocbody $(MANDIR)/toctail > $(REFPATH)/toc.html
	(cat $(MANDIR)/rewritehead ; \
	 echo ; echo "# Aliases hard-coded in refpage markup" ; \
	 sort < $(REFPATH)/rewritebody) > $(REFPATH)/.htaccess
	$(CP) $(MANDIR)/static/*.txt $(REFPATH)

# These targets are HTML5 ref pages
#
# The recursive $(MAKE) is an apparently unavoidable hack, since the
# actual list of man page sources isn't known until after
# $(REFPATH)/apispec.txt is generated. $(GENDEPENDS) is generated before
# running the recursive make, so it doesn't trigger twice
manhtmlpages: $(REFPATH)/apispec.txt $(GENDEPENDS)
	$(MAKE) -e buildmanpages
	$(CP) $(MANDIR)/*.html $(MANDIR)/*.css $(MANDIR)/*.gif $(MANHTMLDIR)
	$(CP) $(REFPATH)/.htaccess $(REFPATH)/*.html $(MANHTMLDIR)

MANHTMLDIR  = $(OUTDIR)/man/html
MANHTML     = $(MANSOURCES:$(REFPATH)/%.txt=$(MANHTMLDIR)/%.html)

buildmanpages: $(MANHTML)

$(MANHTMLDIR)/%.html: KATEXDIR = ../../katex
$(MANHTMLDIR)/%.html: $(REFPATH)/%.txt $(MANCOPYRIGHT) $(GENDEPENDS) $(KATEXINST)
	$(QUIET)$(MKDIR) $(MANHTMLDIR)
	$(QUIET)$(ASCIIDOCTOR) -b html5 -a cross-file-links \
	    $(ADOCMANOPTS) $(ADOCHTMLOPTS) -o $@ $<

$(MANHTMLDIR)/intro.html: $(REFPATH)/intro.txt $(MANCOPYRIGHT)
	$(QUIET)$(MKDIR) $(MANHTMLDIR)
	$(QUIET)$(ASCIIDOCTOR) -b html5 -a cross-file-links \
	    $(ADOCOPTS) $(ADOCHTMLOPTS) -o $@ $<

# Targets generated from the XML and registry processing scripts
#   api.py - Python encoding of the registry
#   $(APIINCDIR)/timeMarker - proxy for 'apiinc' - generate API interfaces
#
# $(GENSCRIPTEXTRA) are extra options that can be passed to the
# generation script, such as
#   '-diag diag'

REGISTRY       = xml
APIXML	       = $(REGISTRY)/cl.xml
GENSCRIPT      = $(SCRIPTS)/gencl.py
DICTSCRIPT     = $(SCRIPTS)/gen_dictionaries.py
VERSIONSCRIPT  = $(SCRIPTS)/gen_version_notes.py
GENSCRIPTOPTS  = $(VERSIONOPTIONS) $(EXTOPTIONS) $(GENSCRIPTEXTRA) -registry $(APIXML)
GENSCRIPTEXTRA =

$(GENERATED)/api.py: $(APIXML) $(GENSCRIPT)
	$(QUIET)$(PYTHON) $(GENSCRIPT) $(GENSCRIPTOPTS) -o $(GENERATED) api.py

apiinc: $(APIINCDIR)/timeMarker

$(APIINCDIR)/timeMarker: $(APIXML) $(DICTSCRIPT) $(GENSCRIPT) $(VERSIONSCRIPT)
	$(QUIET)$(MKDIR) $(APIINCDIR)
	$(QUIET)$(PYTHON) $(DICTSCRIPT) -registry $(APIXML) -o $(APIINCDIR)
	$(QUIET)$(MKDIR) $(VERSIONDIR)
	$(QUIET)$(PYTHON) $(VERSIONSCRIPT) -registry $(APIXML) -o $(VERSIONDIR)
	$(QUIET)$(PYTHON) $(GENSCRIPT) $(GENSCRIPTOPTS) -o $(APIINCDIR) apiinc
