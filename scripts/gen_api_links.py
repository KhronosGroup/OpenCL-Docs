#!/usr/bin/python3

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

from collections import OrderedDict

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
    return """// Copyright 2017-2019 The Khronos Group. This work is licensed under a
// Creative Commons Attribution 4.0 International License; see
// http://creativecommons.org/licenses/by/4.0/

"""

# File Footer:
def GetFooter():
    return """
"""

if __name__ == "__main__":
	nameFuncsDoc = 'api-funcs.asciidoc'
	nameEnumsDoc = 'api-enums.asciidoc'

	nameXMLFile = 'cl.xml'

	specpath = "cl.xml"

	if len(sys.argv) > 1:
		specpath = sys.argv[1]

	print('Generating dictionaries from: ' + specpath)

	spec = parse_xml(specpath)

	# Generate the API functions dictionary:

	funcFile = open(nameFuncsDoc, 'w')
	funcFile.write( GetHeader() )
	numberOfFuncs = 0

	for feature in spec.findall('feature/require'):
		for api in feature.findall('command'):
			name = api.get('name')
			#print('found api: ' + name)

			# Create a variant of the name that precedes underscores with
			# "zero width" spaces.  This causes some long names to be
			# broken at more intuitive places.
			sName = name.replace("_", "_&#8203;")

			# Example:
			#
			# // clEnqueueNDRangeKernel
			# :clEnqueueNDRangeKernel_label: pass:q[*clEnqueueNDRangeKernel*]
			# :clEnqueueNDRangeKernel: <<clEnqueueNDRangeKernel,{clEnqueueNDRangeKernel_label}>>
			funcFile.write('// ' + name + '\n')
			funcFile.write(':' + name + '_label: pass:q[*' + sName + '*]\n')
			funcFile.write(':' + name + ': <<' + name + ',{' + name + '_label}>>\n')
			funcFile.write('\n')

			numberOfFuncs = numberOfFuncs + 1

	funcFile.write( GetFooter() )
	funcFile.close()
	('Successfully generated file: ' + nameFuncsDoc)
	print('Found ' + str(numberOfFuncs) + ' API functions.')
	
	# Generate the API enums dictionary:

	enumFile = open(nameEnumsDoc, 'w')
	enumFile.write( GetHeader() )
	numberOfEnums = 0

	for enums in spec.findall('enums'):
		# Skip Vendor Extension Enums
		vendor = enums.get('vendor')
		if not vendor or vendor == 'Khronos':
			for enum in enums.findall('enum'):
				name = enum.get('name')
				#print('found enum: ' + name)

				# Create a variant of the name that precedes underscores with
				# "zero width" spaces.  This causes some long names to be
				# broken at more intuitive places.
				sName = name.replace("_", "_&#8203;")

				# Example:
				#
				# // CL_MEM_READ_ONLY
				#:CL_MEM_READ_ONLY_label: pass:q[`CL_MEM_READ_ONLY`]
				#:CL_MEM_READ_ONLY: <<CL_MEM_READ_ONLY,{CL_MEM_READ_ONLY_label}>>
				#:CL_MEM_READ_ONLY_anchor: [[CL_MEM_READ_ONLY]]{CL_MEM_READ_ONLY}
				enumFile.write('// ' + name + '\n')
				enumFile.write(':' + name + '_label: pass:q[`' + sName + '`]\n')
				enumFile.write(':' + name + ': <<' + name + ',{' + name + '_label}>>\n')
				enumFile.write(':' + name + '_anchor: [[' + name + ']]{' + name + '}\n')
				enumFile.write('\n')

				numberOfEnums = numberOfEnums + 1

	enumFile.write( GetFooter() )
	enumFile.close()
	print('Successfully generated file: ' + nameEnumsDoc)
	print('Found ' + str(numberOfEnums) + ' API enumerations.')
