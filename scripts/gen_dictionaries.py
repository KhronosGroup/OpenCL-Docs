#!/usr/bin/python3

# Copyright 2019-2024 The Khronos Group Inc.
# SPDX-License-Identifier: Apache-2.0

from collections import OrderedDict

import argparse
import sys
import urllib
import xml.etree.ElementTree as etree
import urllib.request

def parse_xml(path):
    file = urllib.request.urlopen(path) if path.startswith("http") else open(path, 'r')
    with file:
        tree = etree.parse(file)
        return tree

# File Header:
def GetHeader():
    return """// Copyright 2017-2024 The Khronos Group.
// SPDX-License-Identifier: CC-BY-4.0

"""

# File Footer:
def GetFooter():
    return """
"""

if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument('-registry', action='store',
                        default='cl.xml',
                        help='Use specified registry file instead of cl.xml')
    parser.add_argument('-o', action='store', dest='directory',
                        default='.',
                        help='Create target and related files in specified directory')

    args = parser.parse_args()

    apiLinkFileName      = args.directory + '/api-dictionary.asciidoc'
    apiNoLinkFileName    = args.directory + '/api-dictionary-no-links.asciidoc'
    apiTypeFileName      = args.directory + '/api-types.txt'

    extNoLinkFileName    = args.directory + '/ext-dictionary-no-links.asciidoc'
    extFullLinkFileName  = args.directory + '/ext-dictionary-full-links.asciidoc'
    extLocalLinkFileName = args.directory + '/ext-dictionary-local-links.asciidoc'

    specpath = args.registry
    #specpath = "https://raw.githubusercontent.com/KhronosGroup/OpenCL-Registry/main/xml/cl.xml"

    print('Generating dictionaries from: ' + specpath)

    spec = parse_xml(specpath)

    apiLinkFile = open(apiLinkFileName, 'w')
    apiNoLinkFile = open(apiNoLinkFileName, 'w')
    apiLinkFile.write( GetHeader() )
    apiNoLinkFile.write( GetHeader() )
    apiTypeFile = open(apiTypeFileName, 'w')

    extNoLinkFile = open(extNoLinkFileName, 'w')
    extNoLinkFile.write( GetHeader() )
    extFullLinkFile = open(extFullLinkFileName, 'w')
    extFullLinkFile.write( GetHeader() )
    extLocalLinkFile = open(extLocalLinkFileName, 'w')
    extLocalLinkFile.write( GetHeader() )

    # Generate the API functions dictionaries:

    numberOfFuncs = 0

    # Add core API functions with and without links:
    for feature in spec.findall('feature/require'):
        for api in feature.findall('command'):
            name = api.get('name')
            #print('found api: ' + name)

            # Example with link:
            #
            # // clEnqueueNDRangeKernel
            # :clEnqueueNDRangeKernel_label: pass:q[*clEnqueueNDRangeKernel*]
            # :clEnqueueNDRangeKernel: <<clEnqueueNDRangeKernel,{clEnqueueNDRangeKernel_label}>>
            apiLinkFile.write('// ' + name + '\n')
            apiLinkFile.write(':' + name + '_label: pass:q[*' + name + '*]\n')
            apiLinkFile.write(':' + name + ': <<' + name + ',{' + name + '_label}>>\n')
            apiLinkFile.write('\n')

            # Example without link:
            #
            # // clEnqueueNDRangeKernel
            # :clEnqueueNDRangeKernel: pass:q[*clEnqueueNDRangeKernel*]
            apiNoLinkFile.write('// ' + name + '\n')
            apiNoLinkFile.write(':' + name + ': pass:q[*' + name + '*]\n')
            apiNoLinkFile.write('\n')

            numberOfFuncs = numberOfFuncs + 1

    # Add extension API functions without links:
    for extension in spec.findall('extensions/extension/require'):
        for api in extension.findall('command'):
            name = api.get('name')
            #print('found extension api: ' +name)

            # Example without link:
            #
            # // clGetGLObjectInfo
            # :clGetGLObjectInfo: pass:q[*clGetGLObjectInfo*]
            apiLinkFile.write('// ' + name + '\n')
            apiLinkFile.write(':' + name + ': pass:q[*' + name + '*]\n')
            apiLinkFile.write('\n')

            apiNoLinkFile.write('// ' + name + '\n')
            apiNoLinkFile.write(':' + name + ': pass:q[*' + name + '*]\n')
            apiNoLinkFile.write('\n')

            numberOfFuncs = numberOfFuncs + 1

    print('Found ' + str(numberOfFuncs) + ' API functions.')

    # Generate the API enums dictionaries:

    numberOfEnums = 0

    for enums in spec.findall('enums'):
        name = enums.get('name')
        for enum in enums.findall('enum'):
            name = enum.get('name')
            #print('found enum: ' + name)

            # Create a variant of the name that precedes underscores with
            # "zero width" spaces.  This causes some long names to be
            # broken at more intuitive places.
            htmlName = name[:3] + name[3:].replace("_", "_<wbr>")
            otherName = name[:3] + name[3:].replace("_", "_&#8203;")

            # Example with link:
            #
            # // CL_MEM_READ_ONLY
            #:CL_MEM_READ_ONLY_label: pass:q[`CL_MEM_READ_ONLY`]
            #:CL_MEM_READ_ONLY: <<CL_MEM_READ_ONLY,{CL_MEM_READ_ONLY_label}>>
            #:CL_MEM_READ_ONLY_anchor: [[CL_MEM_READ_ONLY]]{CL_MEM_READ_ONLY}
            apiLinkFile.write('// ' + name + '\n')
            apiLinkFile.write('ifdef::backend-html5[]\n')
            apiLinkFile.write(':' + name + '_label: pass:q[`' + htmlName + '`]\n')
            apiLinkFile.write('endif::[]\n')
            apiLinkFile.write('ifndef::backend-html5[]\n')
            apiLinkFile.write(':' + name + '_label: pass:q[`' + otherName + '`]\n')
            apiLinkFile.write('endif::[]\n')
            apiLinkFile.write(':' + name + ': <<' + name + ',{' + name + '_label}>>\n')
            apiLinkFile.write(':' + name + '_anchor: [[' + name + ']]{' + name + '}\n')
            apiLinkFile.write('\n')

            # Example without link:
            #
            # // CL_MEM_READ_ONLY
            #:CL_MEM_READ_ONLY: pass:q[`CL_MEM_READ_ONLY`]
            #:CL_MEM_READ_ONLY_anchor: {CL_MEM_READ_ONLY}
            apiNoLinkFile.write('// ' + name + '\n')
            apiNoLinkFile.write('ifdef::backend-html5[]\n')
            apiNoLinkFile.write(':' + name + ': pass:q[`' + htmlName + '`]\n')
            apiNoLinkFile.write('endif::[]\n')
            apiNoLinkFile.write('ifndef::backend-html5[]\n')
            apiNoLinkFile.write(':' + name + ': pass:q[`' + otherName + '`]\n')
            apiNoLinkFile.write('endif::[]\n')
            apiNoLinkFile.write(':' + name + '_anchor: {' + name + '}\n')
            apiNoLinkFile.write('\n')

            numberOfEnums = numberOfEnums + 1

    print('Found ' + str(numberOfEnums) + ' API enumerations.')

    # Generate the API macro dictionaries:

    numberOfMacros = 0

    for types in spec.findall('types'):
        for type in types.findall('type'):
            name = ""
            category = type.get('category')
            if category == 'define':
                if type.text and type.text.startswith("#define"):
                    name = type.find('name').text
                else:
                    continue
            else:
                continue

            #print('found macro: ' +name)

            # Create a variant of the name that precedes underscores with
            # "zero width" spaces.  This causes some long names to be
            # broken at more intuitive places.
            htmlName = name[:3] + name[3:].replace("_", "_<wbr>")
            otherName = name[:3] + name[3:].replace("_", "_&#8203;")

            # Example with link:
            #
            # // CL_MAKE_VERSION
            #:CL_MAKE_VERSION_label: pass:q[`CL_MAKE_VERSION`]
            #:CL_MAKE_VERSION: <<CL_MAKE_VERSION,{CL_MAKE_VERSION_label}>>
            #:CL_MAKE_VERSION_anchor: [[CL_MAKE_VERSION]]{CL_MAKE_VERSION}
            apiLinkFile.write('// ' + name + '\n')
            apiLinkFile.write('ifdef::backend-html5[]\n')
            apiLinkFile.write(':' + name + '_label: pass:q[`' + htmlName + '`]\n')
            apiLinkFile.write('endif::[]\n')
            apiLinkFile.write('ifndef::backend-html5[]\n')
            apiLinkFile.write(':' + name + '_label: pass:q[`' + otherName + '`]\n')
            apiLinkFile.write('endif::[]\n')
            apiLinkFile.write(':' + name + ': <<' + name + ',{' + name + '_label}>>\n')
            apiLinkFile.write(':' + name + '_anchor: [[' + name + ']]{' + name + '}\n')
            apiLinkFile.write('\n')

            # Example without link:
            #
            # // CL_MAKE_VERSION
            #:CL_MAKE_VERSION: pass:q[`CL_MAKE_VERSION`]
            #:CL_MAKE_VERSION_anchor: {CL_MAKE_VERSION}
            apiNoLinkFile.write('// ' + name + '\n')
            apiNoLinkFile.write('ifdef::backend-html5[]\n')
            apiNoLinkFile.write(':' + name + ': pass:q[`' + htmlName + '`]\n')
            apiNoLinkFile.write('endif::[]\n')
            apiNoLinkFile.write('ifndef::backend-html5[]\n')
            apiNoLinkFile.write(':' + name + ': pass:q[`' + otherName + '`]\n')
            apiNoLinkFile.write('endif::[]\n')
            apiNoLinkFile.write(':' + name + '_anchor: {' + name + '}\n')
            apiNoLinkFile.write('\n')

            numberOfMacros = numberOfMacros + 1

    print('Found ' + str(numberOfMacros) + ' API macros.')

    # Generate the API types dictionaries:

    numberOfTypes = 0

    for types in spec.findall('types'):
        for type in types.findall('type'):
            addLink = False
            name = ""
            category = type.get('category')
            if category == 'basetype':
                name = type.get('name')
            elif category == 'struct':
                addLink = True
                name = type.get('name')
            elif category == 'define':
                if type.text and type.text.startswith("#define"):
                    continue
                name = type.find('name').text
            else:
                continue

            #print('found type: ' +name)

            # Create a variant of the name that precedes underscores with
            # "zero width" spaces.  This causes some long names to be
            # broken at more intuitive places.
            if name.endswith('_t'):
                htmlName = name
                otherName = name
            else:
                htmlName = name[:3] + name[3:].replace("_", "_<wbr>")
                otherName = name[:3] + name[3:].replace("_", "_&#8203;")

            # Some types can have spaces in the name (such as unsigned char),
            # but Asciidoctor attributes cannot.  So, replace spaces with
            # underscores for the attribute name.
            attribName = name.replace(" ", "_")

            # Append the type suffix for disambiguation, since asciidoctor
            # attributes are not case-sensitive (currently).
            attribName = attribName + "_TYPE"

            # Example with link:
            #
            # // cl_image_desc
            # :cl_image_desc_TYPE_label: pass:q[`cl_image_desc`]
            # :cl_image_desc_TYPE: <<cl_image_desc,{cl_image_desc_TYPE_label}>>
            apiLinkFile.write('// ' + name + '\n')
            if addLink:
                apiLinkFile.write('ifdef::backend-html5[]\n')
                apiLinkFile.write(':' + attribName + '_label: pass:q[`' + htmlName + '`]\n')
                apiLinkFile.write('endif::[]\n')
                apiLinkFile.write('ifndef::backend-html5[]\n')
                apiLinkFile.write(':' + attribName + '_label: pass:q[`' + otherName + '`]\n')
                apiLinkFile.write('endif::[]\n')
                apiLinkFile.write(':' + attribName + ': <<' + name + ',{' + attribName + '_label}>>\n')
            else:
                apiLinkFile.write('ifdef::backend-html5[]\n')
                apiLinkFile.write(':' + attribName + ': pass:q[`' + htmlName + '`]\n')
                apiLinkFile.write('endif::[]\n')
                apiLinkFile.write('ifndef::backend-html5[]\n')
                apiLinkFile.write(':' + attribName + ': pass:q[`' + otherName + '`]\n')
                apiLinkFile.write('endif::[]\n')
            apiLinkFile.write('\n')

            # // cl_image_desc
            # :cl_image_desc_TYPE: pass:q[`cl_image_desc`]
            apiNoLinkFile.write('// ' + name + '\n')
            apiNoLinkFile.write('ifdef::backend-html5[]\n')
            apiNoLinkFile.write(':' + attribName + ': pass:q[`' + htmlName + '`]\n')
            apiNoLinkFile.write('endif::[]\n')
            apiNoLinkFile.write('ifndef::backend-html5[]\n')
            apiNoLinkFile.write(':' + attribName + ': pass:q[`' + otherName + '`]\n')
            apiNoLinkFile.write('endif::[]\n')
            apiNoLinkFile.write('\n')

            # Print the type list to a file for custom syntax highlighting.
            # For this we only care about CL types, not base types.
            if category != 'basetype':
                apiTypeFile.write('        ' + name + '\n')

            numberOfTypes = numberOfTypes + 1

    print('Found ' + str(numberOfTypes) + ' API types.')

    # Generate the extension dictionaries:

    numberOfExtensions = 0

    for extension in spec.findall('extensions/extension'):
        name = extension.get('name')
        #print('found extension: ' + name)

        # Create a variant of the name that precedes underscores with
        # "zero width" spaces.  This causes some long names to be
        # broken at more intuitive places.
        htmlName = name[:3] + name[3:].replace("_", "_<wbr>")
        otherName = name[:3] + name[3:].replace("_", "_&#8203;")

        # Append the extension suffix for disambiguation, since we use
        # the extension name as an attribute to enable and disable
        # inclusion of the extension.
        attribName = name + "_EXT"

        # Example with no link:
        #
        # // cl_khr_fp64
        #:cl_khr_fp64_EXT_label: pass:q[`cl_khr_fp64`]
        #:cl_khr_fp64_EXT: [{cl_khr_fp64_EXT_label}]
        extNoLinkFile.write('// ' + name + '\n')
        extNoLinkFile.write('ifdef::backend-html5[]\n')
        extNoLinkFile.write(':' + attribName + ': pass:q[`' + htmlName + '`]\n')
        extNoLinkFile.write('endif::[]\n')
        extNoLinkFile.write('ifndef::backend-html5[]\n')
        extNoLinkFile.write(':' + attribName + ': pass:q[`' + otherName + '`]\n')
        extNoLinkFile.write('endif::[]\n')
        extNoLinkFile.write('\n')

        # Example with full link:
        #
        # // cl_khr_fp64
        #:cl_khr_fp64_EXT_label: pass:q[`cl_khr_fp64`]
        #:cl_khr_fp64_EXT: https://www.khronos.org/registry/OpenCL/specs/3.0-unified/html/OpenCL_API.html#cl_khr_fp64[{cl_khr_fp64_EXT_label}^]
        extFullLinkFile.write('// ' + name + '\n')
        extFullLinkFile.write('ifdef::backend-html5[]\n')
        extFullLinkFile.write(':' + attribName + '_label: pass:q[`' + htmlName + '`]\n')
        extFullLinkFile.write('endif::[]\n')
        extFullLinkFile.write('ifndef::backend-html5[]\n')
        extFullLinkFile.write(':' + attribName + '_label: pass:q[`' + otherName + '`]\n')
        extFullLinkFile.write('endif::[]\n')
        extFullLinkFile.write(':' + attribName + ': https://www.khronos.org/registry/OpenCL/specs/3.0-unified/html/OpenCL_API.html#' + name + '[{' + attribName + '_label}^]\n')
        extFullLinkFile.write('\n')

        # Example with local link:
        #
        # // cl_khr_fp64
        #:cl_khr_fp64_EXT_label: pass:q[`cl_khr_fp64`]
        #:cl_khr_fp64_EXT: <<cl_khr_fp64,{cl_khr_fp64_EXT_label}>>
        extLocalLinkFile.write('// ' + name + '\n')
        extLocalLinkFile.write('ifdef::backend-html5[]\n')
        extLocalLinkFile.write(':' + attribName + '_label: pass:q[`' + htmlName + '`]\n')
        extLocalLinkFile.write('endif::[]\n')
        extLocalLinkFile.write('ifndef::backend-html5[]\n')
        extLocalLinkFile.write(':' + attribName + '_label: pass:q[`' + otherName + '`]\n')
        extLocalLinkFile.write('endif::[]\n')
        extLocalLinkFile.write(':' + attribName + ': <<' + name + ',{' + attribName + '_label}>>\n')
        extLocalLinkFile.write('\n')

        numberOfExtensions = numberOfExtensions + 1

    print('Found ' + str(numberOfExtensions) + ' extensions.')

    apiLinkFile.write( GetFooter() )
    apiLinkFile.close()
    apiNoLinkFile.write( GetFooter() )
    apiNoLinkFile.close()
    apiTypeFile.close()

    extNoLinkFile.write( GetFooter() )
    extNoLinkFile.close()
    extFullLinkFile.write( GetFooter() )
    extFullLinkFile.close()
    extLocalLinkFile.write( GetFooter() )
    extLocalLinkFile.close()

    print('Successfully generated file: ' + apiLinkFileName)
    print('Successfully generated file: ' + apiNoLinkFileName)
    print('Successfully generated file: ' + apiTypeFileName)
    print('Successfully generated file: ' + extNoLinkFileName)
    print('Successfully generated file: ' + extFullLinkFileName)
    print('Successfully generated file: ' + extLocalLinkFileName)

