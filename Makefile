# Copyright 2013-2025 The Khronos Group Inc.
# SPDX-License-Identifier: Apache-2.0

# OpenCL Specifications Makefile
#
# To build the specifications / reference pages (refpages) with optional
# extensions included, set the $(EXTENSIONS) variable on the make
# command line to a space-separated list of extension names.
# $(EXTENSIONS) is converted into generator script
# arguments $(EXTOPTIONS) and into $(ATTRIBFILE)

EXTS := $(sort $(EXTENSIONS))
EXTOPTIONS := $(foreach ext,$(EXTS),-extension $(ext))

QUIET	    ?=
VERYQUIET   ?= @
PYTHON	    ?= python3
ASCIIDOCTOR ?= asciidoctor
RM	    = rm -f
RMRF	    = rm -rf
MKDIR	    = mkdir -p
CP	    = cp
GITHEAD     = ./.git/logs/HEAD

# Where the repo root is
ROOTDIR        = $(CURDIR)
# Where the spec files are
SPECDIR        = $(CURDIR)

# Path to scripts used in generation
SCRIPTS  = $(ROOTDIR)/scripts
# Path to configs and asciidoc extensions used in generation
CONFIGS  = $(ROOTDIR)/config

# Target directories for output files
# HTMLDIR - 'html' target
# PDFDIR - 'pdf' target
# CHECKDIR - 'allchecks' target
OUTDIR	  = out
HTMLDIR   = $(OUTDIR)/html
PDFDIR	  = $(OUTDIR)/pdf
PYAPIMAP  = $(GENERATED)/apimap.py

# PDF Equations are written to SVGs, this dictates the location to store those files (temporary)
PDFMATHDIR = $(OUTDIR)/equations_temp

# Set VERBOSE to -v to see what asciidoc is doing.
VERBOSE =

# asciidoc attributes to set.
# NOTEOPTS   sets options controlling which NOTEs are generated
# ATTRIBOPTS sets the api revision and enables KaTeX generation
# ADOCOPTS   options for asciidoc->HTML5 output (book document type)
# ADOCREFOPTS options for asciidoc->HTML5 output (manpage document type)
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
SPECREMARK = from git branch: $(shell echo `git symbolic-ref --short HEAD 2> /dev/null || echo Git branch not available`) \
	     commit: $(shell echo `git log -1 --format="%H" 2> /dev/null || echo Git commit not available`)
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

# Some of the attributes used in building spec documents:
#   generated - absolute path to generated sources
#   refprefix - controls which generated extension metafiles are
#	included at build time. Must be empty for specification,
#	'refprefix.' for refpages (see ADOCREFOPTS below).
COMMONATTRIBOPTS	= -a revdate="$(SPECDATE)" \
			  -a stem=latexmath \
			  -a generated=$(GENERATED) \
			  -a sectnumlevels=5 \
			  -a nofooter \
			  -a refprefix

ATTRIBOPTS   = -a revnumber="$(SPECREVISION)" \
	       -a revremark="$(SPECREMARK)" \
	       $(COMMONATTRIBOPTS)

CXX4OPENCL_ATTRIBOPTS	= -a revnumber="$(CXX4OPENCL_DOCREVISION)" \
			  -a revremark="$(CXX4OPENCL_DOCREMARK)" \
			  $(COMMONATTRIBOPTS)


ADOCEXTS	      = -r $(CONFIGS)/sectnumoffset-treeprocessor.rb \
			-r $(CONFIGS)/spec-macros.rb \
			-r $(CONFIGS)/rouge_opencl.rb
CXX4OPENCL_ADOCOPTS   = -d book $(CXX4OPENCL_ATTRIBOPTS) $(NOTEOPTS) $(VERBOSE) $(ADOCEXTS)
ADOCCOMMONOPTS	      = -a apispec="$(CURDIR)/api" \
			-a config="$(CONFIGS)" \
			-a cspec="$(CURDIR)/c" \
			-a images="$(CURDIR)/images" \
			$(ATTRIBOPTS) $(NOTEOPTS) $(VERBOSE) $(ADOCEXTS)
ADOCOPTS	      = --failure-level ERROR -d book $(ADOCCOMMONOPTS)

# Asciidoctor options to build refpages
#
# ADOCREFOPTS *must* be placed after ADOCOPTS in the command line, so
# that it can override spec attribute values.
#
# cross-file-links makes custom macros link to other refpages
# refprefix includes the refpage (not spec) extension metadata.
# isrefpage is for refpage-specific content
ADOCREFOPTS	      =  -a cross-file-links -a refprefix='refpage.' \
			 -a isrefpage -d manpage

# ADOCHTMLOPTS relies on the relative runtime path from the output HTML
# file to the katex scripts being set with KATEXDIR. This is overridden
# by some targets.
# ADOCHTMLOPTS also relies on the absolute build-time path to the
# 'stylesdir' containing our custom CSS.
KATEXDIR     = ../katex
ADOCHTMLEXTS = -r $(CONFIGS)/katex_replace.rb
ADOCHTMLOPTS = $(ADOCHTMLEXTS) -a katexpath=$(KATEXDIR) \
	       -a stylesheet=khronos.css -a stylesdir=$(CONFIGS) \
	       -a sectanchors

ADOCPDFEXTS  = -r asciidoctor-pdf -r asciidoctor-mathematical --trace
ADOCPDFOPTS  = $(ADOCPDFEXTS) -a mathematical-format=svg \
	       -a imagesoutdir=$(PDFMATHDIR)

# Where to put dynamically generated dependencies of the spec and other
# targets, from API XML. GENERATED and APIPATH specify the location of
# the API interface includes.
GENERATED  = $(CURDIR)/generated
REFPATH    = $(GENERATED)/refpage
APIPATH    = $(GENERATED)/api
METAPATH   = $(GENERATED)/meta
VERSIONDIR = $(APIPATH)/version-notes
ATTRIBFILE = $(GENERATED)/specattribs.adoc

# timeMarker is a proxy target created when many generated files are
# made at once
APIDEPEND  = $(APIPATH)/timeMarker
METADEPEND = $(METAPATH)/timeMarker
# All generated dependencies
GENDEPENDS = $(APIDEPEND) $(METADEPEND) $(ATTRIBFILE)

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
	@echo APISPECSRC	= $(APISPECSRC)
	@echo CSPECSRC		= $(CSPECSRC)
	@echo ENVSPECSRC	= $(ENVSPECSRC)
	@echo EXTSPECSRC	= $(EXTSPECSRC)
	@echo CEXTDOCSRC	= $(CEXTDOCSRC)
	@echo CXX4OPENCLDOCSRC	= $(CXX4OPENCLDOCSRC)
	@echo CXXSPECSRC	= $(CXXSPECSRC)
	@echo EXTENSIONSSPECSRC = $(EXTENSIONSSPECSRC)
	@echo ICDINSTSPECSRC	= $(ICDINSTSPECSRC)

# API spec

# Top-level spec source file
APISPEC = OpenCL_API
APISPECSRC = $(APISPEC).txt $(GENDEPENDS) \
    $(shell scripts/find_adoc_deps $(APISPEC).txt $(GENERATED))

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
    $(shell scripts/find_adoc_deps $(ENVSPEC).txt $(GENERATED))

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
    $(shell scripts/find_adoc_deps $(EXTSPEC).txt $(GENERATED))

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
    $(shell scripts/find_adoc_deps $(EXTDIR)/$(EXTENSIONSSPEC).txt $(GENERATED))

# Included extension documents
EXTDOCS := $(notdir $(wildcard $(EXTDIR)/[A-Za-z]*.asciidoc))
EXTENSIONS_HTML = $(patsubst %.asciidoc,$(HTMLDIR)/%.html,$(EXTDOCS))
EXTENSIONS_PDF = $(patsubst %.asciidoc,$(PDFDIR)/%.pdf,$(EXTDOCS))

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
    $(shell scripts/find_adoc_deps $(CEXTDOC).txt $(GENERATED))

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
    $(shell scripts/find_adoc_deps $(CXXSPEC).txt $(GENERATED))

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
    $(shell scripts/find_adoc_deps $(CSPEC).txt   $(GENERATED))

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
    $(shell scripts/find_adoc_deps $(CXX4OPENCLDOC).txt $(GENERATED))

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
    $(shell scripts/find_adoc_deps $(ICDINSTSPEC).txt $(GENERATED))

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

clean: clean_html clean_pdf clean_man clean_generated

clean_html:
	$(QUIET)$(RMRF) $(HTMLDIR) $(OUTDIR)/katex

clean_pdf:
	$(QUIET)$(RMRF) $(PDFDIR) $(PDFMATHDIR)

clean_man:
	$(QUIET)$(RMRF) $(MANHTMLDIR)

# Generated directories and files to remove
CLEAN_GEN_PATHS = \
    $(APIPATH) \
    $(METAPATH) \
    $(REFPATH) \
    $(GENERATED)/__pycache__ \
    $(PDFMATHDIR) \
    $(PYAPIMAP) \
    $(ATTRIBFILE)

clean_generated:
	$(QUIET)$(RMRF) $(CLEAN_GEN_PATHS)

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
SPECFILES = $(wildcard api/[A-Za-z]*.asciidoc) $(wildcard c/[A-Za-z]*.asciidoc) OpenCL_API.txt OpenCL_C.txt
GENREF = $(SCRIPTS)/genRef.py
LOGFILE = $(REFPATH)/refpage.log

refpages: $(REFPATH)/apispec.txt
$(REFPATH)/apispec.txt: $(SPECFILES) $(GENREF) $(SCRIPTS)/reflib.py $(PYAPIMAP)
	$(QUIET)$(MKDIR) $(REFPATH)
	$(PYTHON) $(GENREF) -genpath $(GENERATED) -basedir $(REFPATH) \
	    -rewrite $(REFPATH)/rewritebody -toc $(REFPATH)/tocbody \
	    -log $(LOGFILE) -extpath $(CURDIR)/api \
	    $(EXTOPTIONS) $(SPECFILES)
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
# $(SUBMAKEOPTIONS) suppresses the redundant "Entering / leaving"
# messages make normally prints out, similarly to suppressing make
# command output logging in the individual refpage actions below.
SUBMAKEOPTIONS = --no-print-directory
manhtmlpages: $(REFPATH)/apispec.txt $(GENDEPENDS)
	$(QUIET) echo "manhtmlpages: building HTML refpages with these options:"
	$(QUIET) echo $(ASCIIDOCTOR) -b html5 $(ADOCOPTS) $(ADOCHTMLOPTS) \
	    $(ADOCREFOPTS) -o REFPAGE.html REFPAGE.adoc
	$(MAKE) $(SUBMAKEOPTIONS) -e buildmanpages
	$(CP) $(MANDIR)/*.html $(MANDIR)/*.css $(MANDIR)/*.gif $(MANHTMLDIR)
	$(CP) $(REFPATH)/.htaccess $(REFPATH)/*.html $(MANHTMLDIR)

MANHTMLDIR  = $(OUTDIR)/man/html
MANHTML     = $(MANSOURCES:$(REFPATH)/%.txt=$(MANHTMLDIR)/%.html)

buildmanpages: $(MANHTML)

# The refpage build process normally generates far too much output, so
# use VERYQUIET instead of QUIET
$(MANHTMLDIR)/%.html: KATEXDIR = ../../katex
$(MANHTMLDIR)/%.html: $(REFPATH)/%.txt $(MANCOPYRIGHT) $(GENDEPENDS) $(KATEXINST)
	$(VERYQUIET)echo "Building $@ from $< using default options"
	$(VERYQUIET)$(MKDIR) $(MANHTMLDIR)
	$(VERYQUIET)$(ASCIIDOCTOR) -b html5 $(ADOCOPTS) $(ADOCHTMLOPTS) \
	    $(ADOCREFOPTS) -o $@ $<

# This is not formatted as a refpage, so needs a different build rule
$(MANHTMLDIR)/intro.html: $(REFPATH)/intro.txt $(MANCOPYRIGHT)
	$(VERYQUIET)echo "Building $@ from $< using default options"
	$(VERYQUIET)$(MKDIR) $(MANHTMLDIR)
	$(VERYQUIET)$(ASCIIDOCTOR) -b html5 $(ADOCOPTS) $(ADOCHTMLOPTS) \
	    -o $@ $<

# Targets generated from the XML and registry processing scripts
#   apimap.py - Python encoding of the registry
#   apiinc / proxy $(APIDEPEND) - API interface include files in $(APIPATH)
#   extinc / proxy $(METADEPEND) - extension appendix metadata include files in $(METAPATH)
#
# $(GENSCRIPTEXTRA) are extra options that can be passed to the
# generation script, such as
#   '-diag diag'

REGISTRY       = $(ROOTDIR)/xml
APIXML	       = $(REGISTRY)/cl.xml
CFEATURES      = c/features.txt
CFUNCTIONS     = c/functions.txt
GENSCRIPT      = $(SCRIPTS)/gencl.py
DICTSCRIPT     = $(SCRIPTS)/gen_dictionaries.py
VERSIONSCRIPT  = $(SCRIPTS)/gen_version_notes.py
CFEATSCRIPT    = $(SCRIPTS)/gen_dictionary_from_file.py
CFUNCSCRIPT    = $(SCRIPTS)/gen_dictionary_from_file.py
GENSCRIPTOPTS  = $(VERSIONOPTIONS) $(EXTOPTIONS) $(GENSCRIPTEXTRA) -registry $(APIXML)
GENSCRIPTEXTRA =

PYAPIMAP  = $(GENERATED)/apimap.py

scriptapi: pyapi

pyapi $(PYAPIMAP): $(APIXML) $(GENSCRIPT)
	$(QUIET)$(MKDIR) $(GENERATED)
	$(QUIET)$(PYTHON) $(GENSCRIPT) $(GENSCRIPTOPTS) -o $(GENERATED) apimap.py

apiinc: $(APIDEPEND)

$(APIDEPEND): $(APIXML) $(DICTSCRIPT) $(GENSCRIPT) $(VERSIONSCRIPT)
	$(QUIET)$(MKDIR) $(APIPATH)
	$(QUIET)$(PYTHON) $(DICTSCRIPT) -registry $(APIXML) -o $(APIPATH)
	$(QUIET)$(MKDIR) $(VERSIONDIR)
	$(QUIET)$(PYTHON) $(VERSIONSCRIPT) -registry $(APIXML) -o $(VERSIONDIR)
	$(QUIET)$(PYTHON) $(GENSCRIPT) $(GENSCRIPTOPTS) -o $(APIPATH) apiinc

extinc: $(METADEPEND)

$(METADEPEND): $(APIXML) $(GENSCRIPT)
	$(QUIET)$(MKDIR) $(METAPATH)
	$(QUIET)$(PYTHON) $(GENSCRIPT) $(GENSCRIPTOPTS) -o $(METAPATH) extinc
	$(QUIET)$(PYTHON) $(CFEATSCRIPT) -i $(CFEATURES) -o $(METAPATH)/c-feature-dictionary.asciidoc
	$(QUIET)$(PYTHON) $(CFUNCSCRIPT) -i $(CFUNCTIONS) -o $(METAPATH)/c-function-dictionary.asciidoc

# This generates a single file containing asciidoc attributes for each
# extension in the spec being built.
attribs: $(ATTRIBFILE)

$(ATTRIBFILE):
	$(QUIET)$(MKDIR) $(dir $@)
	for attrib in $(EXTS) ; do \
	    echo ":$${attrib}:" ; \
	done > $@

# Debugging aid - generate all files from registry XML
generated: $(PYAPIMAP) $(GENDEPENDS)
