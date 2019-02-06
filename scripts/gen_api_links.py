# Copyright (c) 2019 The Khronos Group Inc.
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

import sys
import os
import re

# File Header:
def GetHeader():
    return """// Copyright 2017-2019 The Khronos Group. This work is licensed under a
// Creative Commons Attribution 4.0 International License; see
// http://creativecommons.org/licenses/by/4.0/

"""

# File Footer:
def GetFooter():
    return """
"""

printHelp = False

nameFuncsDoc = 'api-funcs.asciidoc'
nameEnumsDoc = 'api-enums.asciidoc'

nameFuncsDict = 'api-funcs.list'
nameEnumsDict = 'api-enums.list'

if ( len(sys.argv) == 2 ) and ( sys.argv[1] == '-h' or sys.argv[1] == '-?' ):
    printHelp = True

if printHelp:
    print('usage: gen_api_links.py')
elif not os.path.exists(nameFuncsDict) or not os.path.exists(nameEnumsDict):
    print('error: dictionary file ' + nameFuncsDict + ' or ' + nameEnumsDict + ' does not exist!')
else:
    print('Generating funcs from source: ' + nameFuncsDict)

    srcFile = open(nameFuncsDict, 'rU')
    docFile = open(nameFuncsDoc, 'w')

    docFile.write( GetHeader() )

    numberOfFuncs = 0

    for line in srcFile:
        # Skip empty lines or whitespace lines:
        if not line or line.isspace():
            continue

        # Skip comment lines (lines beginning with '#'):
        comment = re.search("^#.*", line)
        if comment:
            continue

        # Strip the trailing newline:
        line = line[0:-1]

        # Create a variant of the name that precedes underscores with
        # "zero width" spaces.  This causes some long names to be
        # broken at more intuitive places.
        sline = line.replace("_", "_&#8203;")

        # Example:
        #
        # // clEnqueueNDRangeKernel
        # :clEnqueueNDRangeKernel_label: pass:q[*clEnqueueNDRangeKernel*]
        # :clEnqueueNDRangeKernel: <<clEnqueueNDRangeKernel,{clEnqueueNDRangeKernel_label}>>
        docFile.write('// ' + line + '\n')
        docFile.write(':' + line + '_label: pass:q[*' + sline + '*]\n')
        docFile.write(':' + line + ': <<' + line + ',{' + line + '_label}>>\n')
        docFile.write('\n')

        numberOfFuncs = numberOfFuncs + 1

        #print('Not sure what to do with: ' + line)

    docFile.write( GetFooter() )

    srcFile.close()
    docFile.close()

    print('Successfully generated file: ' + nameFuncsDoc)
    print('Found ' + str(numberOfFuncs) + ' API functions.')


    print('Generating enums from source: ' + nameEnumsDict)

    srcFile = open(nameEnumsDict, 'rU')
    docFile = open(nameEnumsDoc, 'w')

    docFile.write( GetHeader() )

    numberOfEnums = 0

    for line in srcFile:
        # Skip empty lines or whitespace lines:
        if not line or line.isspace():
            continue

        # Skip comment lines (lines beginning with '#'):
        comment = re.search("^#.*", line)
        if comment:
            continue

        # Strip the trailing newline:
        line = line[0:-1]

        # Create a variant of the name that precedes underscores with
        # "zero width" spaces.  This causes some long names to be
        # broken at more intuitive places.
        sline = line.replace("_", "_&#8203;")

        # Example:
        #
        # // CL_MEM_READ_ONLY
        #:CL_MEM_READ_ONLY_label: pass:q[`CL_MEM_READ_ONLY`]
        #:CL_MEM_READ_ONLY: <<CL_MEM_READ_ONLY,{CL_MEM_READ_ONLY_label}>>
        #:CL_MEM_READ_ONLY_anchor: [[CL_MEM_READ_ONLY]]{CL_MEM_READ_ONLY}
        docFile.write('// ' + line + '\n')
        docFile.write(':' + line + '_label: pass:q[`' + sline + '`]\n')
        docFile.write(':' + line + ': <<' + line + ',{' + line + '_label}>>\n')
        docFile.write(':' + line + '_anchor: [[' + line + ']]{' + line + '}\n')
        docFile.write('\n')

        numberOfEnums = numberOfEnums + 1

        #print('Not sure what to do with: ' + line)

    docFile.write( GetFooter() )

    srcFile.close()
    docFile.close()

    print('Successfully generated file: ' + nameEnumsDoc)
    print('Found ' + str(numberOfEnums) + ' API enumerations.')
