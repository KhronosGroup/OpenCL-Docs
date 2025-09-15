#!/usr/bin/env python3

# Copyright 2019-2025 The Khronos Group Inc.
# SPDX-License-Identifier: Apache-2.0

import argparse
import os
import urllib
import xml.etree.ElementTree as etree
import urllib.request

def parse_xml(path):
    file = urllib.request.urlopen(path) if path.startswith("http") else open(path, 'r')
    with file:
        tree = etree.parse(file)
        return tree

def GetHeader():
    return """// Copyright 2017-2025 The Khronos Group.
// SPDX-License-Identifier: CC-BY-4.0

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

    specpath = args.registry

    print('Generating extension interfaces from: ' + specpath)

    spec = parse_xml(specpath)

    for extension in spec.findall('extensions/extension'):
        extname = extension.get('name')
        #print(extname)
        iface_file = open(os.path.join(args.directory, extname + '.txt'), 'w')

        iface_file.write(GetHeader())

        # New commands
        commands = extension.findall('require/command')
        if commands:
            iface_file.write('=== New Commands\n\n')
            for cmd in commands:
                iface_file.write('  * {{{}}}\n'.format(cmd.get('name')))
            iface_file.write('\n')

        # New types
        types = extension.findall('require/type')
        if types:
            iface_file.write('=== New Types\n\n')
            for ty in types:
                iface_file.write('  * {{{}_TYPE}}\n'.format(ty.get('name')))

        # New enums
        first_enum = True
        requires = extension.findall('require')
        for req in requires:
            enums = req.findall('enum')
            first_for_require = True
            for e in enums:
                if first_enum:
                    iface_file.write('=== New enums\n\n')
                    first_enum = False
                if first_for_require:
                    comment = req.get('comment')
                    if comment == 'Error codes':
                        iface_file.write('  * New Error Codes\n')
                    else:
                        iface_file.write('  * {{{}_TYPE}}\n'.format(comment))
                    first_for_require = False
                iface_file.write('  ** {{{}}}\n'.format(e.get('name')))
            iface_file.write('\n')

        iface_file.close()
