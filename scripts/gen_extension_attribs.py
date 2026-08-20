#!/usr/bin/python3

# Copyright 2024 The Khronos Group Inc.
# SPDX-License-Identifier: Apache-2.0

from collections import OrderedDict

import argparse
import sys

if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument('-tokens', action='store',
                        default='tokens.txt',
                        help='File with extension tokens to generate, one token per line')
    parser.add_argument('-links', action='store_true',
                        help='Generate attributes with links')
    args = parser.parse_args()

    srcpath = args.tokens
    print('Generating dictionaries from: ' + srcpath + ' ...\n\n')

    with open(args.tokens) as f:
        tokens = f.readlines()

    numberOfEnums = 0
    numberOfTypes = 0
    numberOfFuncs = 0

    outfile = sys.stdout

    for name in tokens:
        name = name.strip()
        if len(name) == 0:
            continue

        # enums start with CL_
        if name.startswith('CL_'):
            #print('found enum: ' + name)

            # Create a variant of the name that precedes underscores with
            # "zero width" spaces.  This causes some long names to be
            # broken at more intuitive places.
            htmlName = name[:3] + name[3:].replace("_", "_<wbr>")
            otherName = name[:3] + name[3:].replace("_", "_&#8203;")

            if args.links:
                # Example with link:
                #
                # // CL_MEM_READ_ONLY
                #:CL_MEM_READ_ONLY_label: pass:q[`CL_MEM_READ_ONLY`]
                #:CL_MEM_READ_ONLY: <<CL_MEM_READ_ONLY,{CL_MEM_READ_ONLY_label}>>
                #:CL_MEM_READ_ONLY_anchor: [[CL_MEM_READ_ONLY]]{CL_MEM_READ_ONLY}
                outfile.write('// ' + name + '\n')
                #outfile.write('ifdef::backend-html5[]\n')
                outfile.write(':' + name + '_label: pass:q[`' + htmlName + '`]\n')
                #outfile.write('endif::[]\n')
                #outfile.write('ifndef::backend-html5[]\n')
                #outfile.write(':' + name + '_label: pass:q[`' + otherName + '`]\n')
                #outfile.write('endif::[]\n')
                outfile.write(':' + name + ': <<' + name + ',{' + name + '_label}>>\n')
                outfile.write(':' + name + '_anchor: [[' + name + ']]{' + name + '}\n')
            else:
                # Example without link:
                #
                # // CL_MEM_READ_ONLY
                #:CL_MEM_READ_ONLY: pass:q[`CL_MEM_READ_ONLY`]
                #:CL_MEM_READ_ONLY_anchor: {CL_MEM_READ_ONLY}
                outfile.write('// ' + name + '\n')
                #outfile.write('ifdef::backend-html5[]\n')
                outfile.write(':' + name + ': pass:q[`' + htmlName + '`]\n')
                #outfile.write('endif::[]\n')
                #outfile.write('ifndef::backend-html5[]\n')
                #outfile.write(':' + name + ': pass:q[`' + otherName + '`]\n')
                #outfile.write('endif::[]\n')
                outfile.write(':' + name + '_anchor: {' + name + '}\n')

            numberOfEnums = numberOfEnums + 1

        # types start with cl_
        elif name.startswith('cl_'):
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

            if args.links:
                # Example with link:
                #
                # // cl_image_desc
                # :cl_image_desc_TYPE_label: pass:q[`cl_image_desc`]
                # :cl_image_desc_TYPE: <<cl_image_desc,{cl_image_desc_TYPE_label}>>
                outfile.write('// ' + name + '\n')
                #outfile.write('ifdef::backend-html5[]\n')
                outfile.write(':' + attribName + '_label: pass:q[`' + htmlName + '`]\n')
                #outfile.write('endif::[]\n')
                #outfile.write('ifndef::backend-html5[]\n')
                #outfile.write(':' + attribName + '_label: pass:q[`' + otherName + '`]\n')
                #outfile.write('endif::[]\n')
                outfile.write(':' + attribName + ': <<' + name + ',{' + attribName + '_label}>>\n')
            else:
                # // cl_image_desc
                # :cl_image_desc_TYPE: pass:q[`cl_image_desc`]
                outfile.write('// ' + name + '\n')
                #outfile.write('ifdef::backend-html5[]\n')
                outfile.write(':' + attribName + ': pass:q[`' + htmlName + '`]\n')
                #outfile.write('endif::[]\n')
                #outfile.write('ifndef::backend-html5[]\n')
                #outfile.write(':' + attribName + ': pass:q[`' + otherName + '`]\n')

            numberOfTypes = numberOfTypes + 1

        # OpenCL C features start with __opencl_c
        elif name.startswith('__opencl_c'):
            #print('found enum: ' + name)

            # Create a variant of the name that precedes underscores with
            # "zero width" spaces.  This causes some long names to be
            # broken at more intuitive places.
            htmlName = name[:10] + name[3:].replace("_", "_<wbr>")
            otherName = name[:10] + name[3:].replace("_", "_&#8203;")
        
        # everything else is a function
        else:
            #print('found api: ' + name)

            if args.links:
                # Example with link:
                #
                # // clEnqueueNDRangeKernel
                # :clEnqueueNDRangeKernel_label: pass:q[*clEnqueueNDRangeKernel*]
                # :clEnqueueNDRangeKernel: <<clEnqueueNDRangeKernel,{clEnqueueNDRangeKernel_label}>>
                outfile.write('// ' + name + '\n')
                outfile.write(':' + name + '_label: pass:q[*' + name + '*]\n')
                outfile.write(':' + name + ': <<' + name + ',{' + name + '_label}>>\n')
            else:
                # Example without link:
                #
                # // clEnqueueNDRangeKernel
                # :clEnqueueNDRangeKernel: pass:q[*clEnqueueNDRangeKernel*]
                outfile.write('// ' + name + '\n')
                outfile.write(':' + name + ': pass:q[*' + name + '*]\n')

            numberOfFuncs = numberOfFuncs + 1

        outfile.write('\n')


    print('Found ' + str(numberOfEnums) + ' API enumerations.')
    print('Found ' + str(numberOfTypes) + ' API types.')
    print('Found ' + str(numberOfFuncs) + ' API functions.')
