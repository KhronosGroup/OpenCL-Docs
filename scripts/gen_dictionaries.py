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

    linkFileName   = args.directory + '/api-dictionary.asciidoc'
    nolinkFileName = args.directory + '/api-dictionary-no-links.asciidoc'
    typeFileName   = args.directory + '/api-types.txt'

    specpath = args.registry
    #specpath = "https://raw.githubusercontent.com/KhronosGroup/OpenCL-Registry/main/xml/cl.xml"

    print('Generating dictionaries from: ' + specpath)

    spec = parse_xml(specpath)

    linkFile = open(linkFileName, 'w')
    nolinkFile = open(nolinkFileName, 'w')
    linkFile.write( GetHeader() )
    nolinkFile.write( GetHeader() )
    typeFile = open(typeFileName, 'w')

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
            linkFile.write('// ' + name + '\n')
            linkFile.write(':' + name + '_label: pass:q[*' + name + '*]\n')
            linkFile.write(':' + name + ': <<' + name + ',{' + name + '_label}>>\n')
            linkFile.write('\n')

            # Example without link:
            #
            # // clEnqueueNDRangeKernel
            # :clEnqueueNDRangeKernel: pass:q[*clEnqueueNDRangeKernel*]
            nolinkFile.write('// ' + name + '\n')
            nolinkFile.write(':' + name + ': pass:q[*' + name + '*]\n')
            nolinkFile.write('\n')

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
            linkFile.write('// ' + name + '\n')
            linkFile.write(':' + name + ': pass:q[*' + name + '*]\n')
            linkFile.write('\n')

            nolinkFile.write('// ' + name + '\n')
            nolinkFile.write(':' + name + ': pass:q[*' + name + '*]\n')
            nolinkFile.write('\n')

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
            linkFile.write('// ' + name + '\n')
            linkFile.write('ifdef::backend-html5[]\n')
            linkFile.write(':' + name + '_label: pass:q[`' + htmlName + '`]\n')
            linkFile.write('endif::[]\n')
            linkFile.write('ifndef::backend-html5[]\n')
            linkFile.write(':' + name + '_label: pass:q[`' + otherName + '`]\n')
            linkFile.write('endif::[]\n')
            linkFile.write(':' + name + ': <<' + name + ',{' + name + '_label}>>\n')
            linkFile.write(':' + name + '_anchor: [[' + name + ']]{' + name + '}\n')
            linkFile.write('\n')

            # Example without link:
            #
            # // CL_MEM_READ_ONLY
            #:CL_MEM_READ_ONLY: pass:q[`CL_MEM_READ_ONLY`]
            #:CL_MEM_READ_ONLY_anchor: {CL_MEM_READ_ONLY}
            nolinkFile.write('// ' + name + '\n')
            nolinkFile.write('ifdef::backend-html5[]\n')
            nolinkFile.write(':' + name + ': pass:q[`' + htmlName + '`]\n')
            nolinkFile.write('endif::[]\n')
            nolinkFile.write('ifndef::backend-html5[]\n')
            nolinkFile.write(':' + name + ': pass:q[`' + otherName + '`]\n')
            nolinkFile.write('endif::[]\n')
            nolinkFile.write(':' + name + '_anchor: {' + name + '}\n')
            nolinkFile.write('\n')

            numberOfEnums = numberOfEnums + 1

    print('Found ' + str(numberOfEnums) + ' API enumerations.')

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
            linkFile.write('// ' + name + '\n')
            if addLink:
                linkFile.write('ifdef::backend-html5[]\n')
                linkFile.write(':' + attribName + '_label: pass:q[`' + htmlName + '`]\n')
                linkFile.write('endif::[]\n')
                linkFile.write('ifndef::backend-html5[]\n')
                linkFile.write(':' + attribName + '_label: pass:q[`' + otherName + '`]\n')
                linkFile.write('endif::[]\n')
                linkFile.write(':' + attribName + ': <<' + name + ',{' + attribName + '_label}>>\n')
            else:
                linkFile.write('ifdef::backend-html5[]\n')
                linkFile.write(':' + attribName + ': pass:q[`' + htmlName + '`]\n')
                linkFile.write('endif::[]\n')
                linkFile.write('ifndef::backend-html5[]\n')
                linkFile.write(':' + attribName + ': pass:q[`' + otherName + '`]\n')
                linkFile.write('endif::[]\n')
            linkFile.write('\n')

            # // cl_image_desc
            # :cl_image_desc_TYPE: pass:q[`cl_image_desc`]
            nolinkFile.write('// ' + name + '\n')
            nolinkFile.write('ifdef::backend-html5[]\n')
            nolinkFile.write(':' + attribName + ': pass:q[`' + htmlName + '`]\n')
            nolinkFile.write('endif::[]\n')
            nolinkFile.write('ifndef::backend-html5[]\n')
            nolinkFile.write(':' + attribName + ': pass:q[`' + otherName + '`]\n')
            nolinkFile.write('endif::[]\n')
            nolinkFile.write('\n')

            # Print the type list to a file for custom syntax highlighting.
            # For this we only care about CL types, not base types.
            if category != 'basetype':
                typeFile.write('        ' + name + '\n')

            numberOfTypes = numberOfTypes + 1

    print('Found ' + str(numberOfTypes) + ' API types.')

    linkFile.write( GetFooter() )
    linkFile.close()
    nolinkFile.write( GetFooter() )
    nolinkFile.close()
    typeFile.close()

    print('Successfully generated file: ' + linkFileName)
    print('Successfully generated file: ' + nolinkFileName)
    print('Successfully generated file: ' + typeFileName)

