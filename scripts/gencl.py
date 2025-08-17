#!/usr/bin/env python3
#
# Copyright 2013-2025 The Khronos Group Inc.
#
# SPDX-License-Identifier: Apache-2.0

import argparse
import pdb
import re
import sys
import time
import xml.etree.ElementTree as etree

from cgenerator import CGeneratorOptions, COutputGenerator
from docgenerator import DocGeneratorOptions, DocOutputGenerator
from extensionmetadocgenerator import (ExtensionMetaDocGeneratorOptions,
                                       ExtensionMetaDocOutputGenerator)

from generator import write


from pygenerator import PyOutputGenerator
from reflib import logDiag, logWarn, logErr, setLogFile
from reg import Registry
from apiconventions import APIConventions

# Simple timer functions
startTime = None


def startTimer(timeit):
    global startTime
    if timeit:
        startTime = time.process_time()


def endTimer(timeit, msg):
    global startTime
    if timeit:
        endTime = time.process_time()
        logDiag(msg, endTime - startTime)
        startTime = None


def makeREstring(strings, default=None, strings_are_regex=False):
    """Turn a list of strings into a regexp string matching exactly those strings."""
    if strings or default is None:
        if not strings_are_regex:
            strings = (re.escape(s) for s in strings)
        return '^(' + '|'.join(strings) + ')$'
    return default

def makeGenOpts(args):
    """Returns a directory of [ generator function, generator options ] indexed
    by specified short names. The generator options incorporate the following
    parameters:

    args is an parsed argument object; see below for the fields that are used."""
    global genOpts
    genOpts = {}

    # Default class of extensions to include, or None
    defaultExtensions = args.defaultExtensions

    # Additional extensions to include (list of extensions)
    extensions = args.extension

    # Extensions to remove (list of extensions)
    removeExtensions = args.removeExtensions

    # Extensions to emit (list of extensions)
    emitExtensions = args.emitExtensions

    # SPIR-V capabilities / features to emit (list of extensions & capabilities)
    # emitSpirv = args.emitSpirv

    # Features to include (list of features)
    features = args.feature

    # Whether to disable inclusion protect in headers
    protect = args.protect

    # Output target directory
    directory = args.directory

    # Path to generated files, particularly api.py
    genpath = args.genpath

    # Generate MISRA C-friendly headers
    misracstyle = args.misracstyle;

    # Generate MISRA C++-friendly headers
    misracppstyle = args.misracppstyle;

    # Descriptive names for various regexp patterns used to select
    # versions and extensions
    allSpirv = allFeatures = allExtensions = r'.*'

    # Turn lists of names/patterns into matching regular expressions
    addExtensionsPat     = makeREstring(extensions, None)
    removeExtensionsPat  = makeREstring(removeExtensions, None)
    emitExtensionsPat    = makeREstring(emitExtensions, allExtensions)
    # emitSpirvPat         = makeREstring(emitSpirv, allSpirv)
    featuresPat          = makeREstring(features, allFeatures)

    # Copyright text prefixing all headers (list of strings).
    # The SPDX formatting below works around constraints of the 'reuse' tool
    prefixStrings = [
        '/*',
        '** Copyright 2015-2025 The Khronos Group Inc.',
        '**',
        '** SPDX' + '-License-Identifier: Apache-2.0',
        '*/',
        ''
    ]

    # Text specific to OpenCL headers
    clPrefixStrings = [
        '/*',
        '** This header is generated from the Khronos OpenCL XML API Registry.',
        '**',
        '*/',
        ''
    ]

    # Defaults for generating re-inclusion protection wrappers (or not)
    protectFile = protect

    # An API style conventions object
    conventions = APIConventions()

    if args.apiname is not None:
        defaultAPIName = args.apiname
    else:
        defaultAPIName = conventions.xml_api_name

    # API include files for spec and ref pages
    # Overwrites include subdirectories in spec source tree
    # The generated include files do not include the calling convention
    # macros (apientry etc.), unlike the header files.
    # Because the 1.0 core branch includes ref pages for extensions,
    # all the extension interfaces need to be generated, even though
    # none are used by the core spec itself.
    genOpts['apiinc'] = [
          DocOutputGenerator,
          DocGeneratorOptions(
            conventions       = conventions,
            filename          = 'timeMarker',
            directory         = directory,
            genpath           = genpath,
            apiname           = defaultAPIName,
            profile           = None,
            versions          = featuresPat,
            emitversions      = featuresPat,
            defaultExtensions = defaultExtensions,
            addExtensions     = addExtensionsPat,
            removeExtensions  = removeExtensionsPat,
            emitExtensions    = emitExtensionsPat,
            prefixText        = prefixStrings + clPrefixStrings,
            apicall           = '',
            apientry          = '',
            apientryp         = '*',
            alignFuncParam    = 0,
            expandEnumerants  = False)
        ]

    # Python representation of API information, used by scripts that
    # don't need to load the full XML.
    genOpts['apimap.py'] = [
          PyOutputGenerator,
          DocGeneratorOptions(
            conventions       = conventions,
            filename          = 'apimap.py',
            directory         = directory,
            genpath           = None,
            apiname           = defaultAPIName,
            profile           = None,
            versions          = featuresPat,
            emitversions      = featuresPat,
            defaultExtensions = None,
            addExtensions     = addExtensionsPat,
            removeExtensions  = removeExtensionsPat,
            emitExtensions    = emitExtensionsPat,
            reparentEnums     = False)
        ]


    # Extension metainformation for spec extension appendices
    # Includes all extensions by default, but only so that the generated
    # 'promoted_extensions_*' files refer to all extensions that were
    # promoted to a core version.
    genOpts['extinc'] = [
          ExtensionMetaDocOutputGenerator,
          ExtensionMetaDocGeneratorOptions(
            conventions       = conventions,
            filename          = 'timeMarker',
            directory         = directory,
            genpath           = None,
            apiname           = defaultAPIName,
            profile           = None,
            versions          = featuresPat,
            emitversions      = None,
            defaultExtensions = defaultExtensions,
            addExtensions     = addExtensionsPat,
            removeExtensions  = None,
            emitExtensions    = emitExtensionsPat)
        ]

    # Header for core API + extensions.
    # To generate just the core API,
    # change to 'defaultExtensions = None' below.
    #
    # By default this adds all enabled, non-platform extensions.
    # It removes all platform extensions (from the platform headers options
    # constructed above) as well as any explicitly specified removals.

    removeExtensionsPat = makeREstring(removeExtensions, None,
        strings_are_regex=True)

    genOpts['cl.h'] = [
          COutputGenerator,
          CGeneratorOptions(
            conventions       = conventions,
            filename          = 'cl.h',
            directory         = directory,
            genpath           = None,
            apiname           = defaultAPIName,
            profile           = None,
            versions          = featuresPat,
            emitversions      = featuresPat,
            defaultExtensions = defaultExtensions,
            addExtensions     = None,
            removeExtensions  = removeExtensionsPat,
            emitExtensions    = emitExtensionsPat,
            prefixText        = prefixStrings + clPrefixStrings,
            genFuncPointers   = False,
            protectFile       = protectFile,
            protectFeature    = False,
            protectProto      = '#ifndef',
            protectProtoStr   = 'CL_NO_PROTOTYPES',
            apicall           = 'CL_API_ENTRY ',
            apientry          = 'CL_API_CALL ',
            apientryp         = 'CL_API_CALL *',
            alignFuncParam    = 0,
            misracstyle       = misracstyle,
            misracppstyle     = misracppstyle)
        ]

def genTarget(args):
    """Create an API generator and corresponding generator options based on
    the requested target and command line options.

    This is encapsulated in a function so it can be profiled and/or timed.
    The args parameter is an parsed argument object containing the following
    fields that are used:

    - target - target to generate
    - directory - directory to generate it in
    - protect - True if re-inclusion wrappers should be created
    - extensions - list of additional extensions to include in generated interfaces"""

    # Create generator options with parameters specified on command line
    makeGenOpts(args)

    # pdb.set_trace()

    # Select a generator matching the requested target
    if args.target in genOpts:
        createGenerator = genOpts[args.target][0]
        options = genOpts[args.target][1]

        logDiag('* Building', options.filename)
        logDiag('* options.versions          =', options.versions)
        logDiag('* options.emitversions      =', options.emitversions)
        logDiag('* options.defaultExtensions =', options.defaultExtensions)
        logDiag('* options.addExtensions     =', options.addExtensions)
        logDiag('* options.removeExtensions  =', options.removeExtensions)
        logDiag('* options.emitExtensions    =', options.emitExtensions)

        gen = createGenerator(errFile=errWarn,
                              warnFile=errWarn,
                              diagFile=diag)
        return (gen, options)
    else:
        logErr('No generator options for unknown target:', args.target)
        return None


# -feature name
# -extension name
# For both, "name" may be a single name, or a space-separated list
# of names, or a regular expression.
if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument('-apiname', action='store',
                        default=None,
                        help='Specify API to generate (defaults to repository-specific conventions object value)')
    parser.add_argument('-defaultExtensions', action='store',
                        default=APIConventions().xml_api_name,
                        help='Specify a single class of extensions to add to targets')
    parser.add_argument('-extension', action='append',
                        default=[],
                        help='Specify an extension or extensions to add to targets')
    parser.add_argument('-removeExtensions', action='append',
                        default=[],
                        help='Specify an extension or extensions to remove from targets')
    parser.add_argument('-emitExtensions', action='append',
                        default=[],
                        help='Specify an extension or extensions to emit in targets')



    parser.add_argument('-feature', action='append',
                        default=[],
                        help='Specify a core API feature name or names to add to targets')
    parser.add_argument('-debug', action='store_true',
                        help='Enable debugging')
    parser.add_argument('-dump', action='store_true',
                        help='Enable dump to stderr')
    parser.add_argument('-diagfile', action='store',
                        default=None,
                        help='Write diagnostics to specified file')
    parser.add_argument('-errfile', action='store',
                        default=None,
                        help='Write errors and warnings to specified file instead of stderr')
    parser.add_argument('-noprotect', dest='protect', action='store_false',
                        help='Disable inclusion protection in output headers')
    parser.add_argument('-profile', action='store_true',
                        help='Enable profiling')
    parser.add_argument('-registry', action='store',
                        default='cl.xml',
                        help='Use specified registry file instead of cl.xml')
    parser.add_argument('-time', action='store_true',
                        help='Enable timing')
    parser.add_argument('-validate', action='store_true',
                        help='Validate the registry properties and exit')
    parser.add_argument('-genpath', action='store', default='gen',
                        help='Path to generated files')
    parser.add_argument('-o', action='store', dest='directory',
                        default='.',
                        help='Create target and related files in specified directory')
    parser.add_argument('target', metavar='target', nargs='?',
                        help='Specify target')
    parser.add_argument('-quiet', action='store_true', default=True,
                        help='Suppress script output during normal execution.')
    parser.add_argument('-verbose', action='store_false', dest='quiet', default=True,
                        help='Enable script output during normal execution.')
    parser.add_argument('-misracstyle', dest='misracstyle', action='store_true',
                        help='generate MISRA C-friendly headers')
    parser.add_argument('-misracppstyle', dest='misracppstyle', action='store_true',
                        help='generate MISRA C++-friendly headers')

    args = parser.parse_args()

    # This splits arguments which are space-separated lists
    args.feature = [name for arg in args.feature for name in arg.split()]
    args.extension = [name for arg in args.extension for name in arg.split()]

    # create error/warning & diagnostic files
    if args.errfile:
        errWarn = open(args.errfile, 'w', encoding='utf-8')
    else:
        errWarn = sys.stderr

    if args.diagfile:
        diag = open(args.diagfile, 'w', encoding='utf-8')
    else:
        diag = None

    if args.time:
        # Log diagnostics and warnings
        setLogFile(setDiag = True, setWarn = True, filename = '-')

    # Create the API generator & generator options
    (gen, options) = genTarget(args)

    # Create the registry object with the specified generator and generator
    # options. The options are set before XML loading as they may affect it.
    reg = Registry(gen, options)

    # Parse the specified registry XML into an ElementTree object
    startTimer(args.time)
    tree = etree.parse(args.registry)
    endTimer(args.time, '* Time to make ElementTree =')

    # Load the XML tree into the registry object
    startTimer(args.time)
    reg.loadElementTree(tree)
    endTimer(args.time, '* Time to parse ElementTree =')

    if args.dump:
        logDiag('* Dumping registry to regdump.txt')
        reg.dumpReg(filehandle=open('regdump.txt', 'w', encoding='utf-8'))

    # Finally, use the output generator to create the requested target
    if args.debug:
        pdb.run('reg.apiGen()')
    else:
        startTimer(args.time)
        reg.apiGen()
        endTimer(args.time, '* Time to generate ' + options.filename + ' =')

    if not args.quiet:
        logDiag('* Generated', options.filename)
