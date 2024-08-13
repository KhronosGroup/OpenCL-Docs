#!/usr/bin/python3

# Copyright 2024 The Khronos Group Inc.
# SPDX-License-Identifier: Apache-2.0

from collections import OrderedDict

import argparse
import sys

if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument('-features', action='store',
                        default='',
                        help='File with OpenCL C features to generate, one per line')
    parser.add_argument('-o', action='store', default='',
                        help='Output file in which to store the feature dictionary. stdout is used if no file is provided.')

    args = parser.parse_args()

    features = []
    if len(args.features) > 0:
        print('Generating feature dictionaries from: ' + args.features)
        with open(args.features) as f:
            features = f.readlines()
    else:
        print('Reading feature dictionaries from stdin...')
        for line in sys.stdin:
            features.append(line)
        print('Generating...\n')

    numberOfFeatures = 0

    if args.o:
        outfile = open(args.o, 'w')
    else:
        outfile = sys.stdout

    for name in features:
        name = name.strip()
        if len(name) == 0:
            continue

        # OpenCL C features start with __opencl_c
        if name.startswith('__opencl_c'):
            #print('found enum: ' + name)

            # Create a variant of the name that precedes underscores with
            # "zero width" spaces.  This causes some long names to be
            # broken at more intuitive places.
            htmlName = name[:10] + name[10:].replace("_", "_<wbr>")
            otherName = name[:10] + name[10:].replace("_", "_&#8203;")

            # Remove the leading underscores.
            name = name[2:]

            # Example:
            #
            # // opencl_c_images
            # ifdef::backend-html5[]
            # :opencl_c_images: pass:q[`\__opencl_c_<wbr>images`]
            # endif::[]
            # ifndef::backend-html5[]
            # :opencl_c_images: pass:q[`\__opencl_c_&#8203;images`]
            # endif::[]
            outfile.write('// ' + name + '\n')
            outfile.write('ifdef::backend-html5[]\n')
            outfile.write(':' + name + ': pass:q[`\\' + htmlName + '`]\n')
            outfile.write('endif::[]\n')
            outfile.write('ifndef::backend-html5[]\n')
            outfile.write(':' + name + ': pass:q[`\\' + otherName + '`]\n')
            outfile.write('endif::[]\n')

            numberOfFeatures = numberOfFeatures + 1

        # everything else is a function
        else:
            print('Unexpected feature name: ' + name + ', features should start with __opencl_c!')
            sys.exit(1)

        outfile.write('\n')

    if args.o:
        outfile.close()

    print('Found ' + str(numberOfFeatures) + ' features.')
