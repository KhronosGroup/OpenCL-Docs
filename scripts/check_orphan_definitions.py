#!/usr/bin/python3

# Copyright 2019-2021 The Khronos Group Inc.
# SPDX-License-Identifier: Apache-2.0

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

if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument('-registry', action='store',
                        default='cl.xml',
                        help='Use specified registry file instead of cl.xml')

    args = parser.parse_args()

    specpath = args.registry
    #specpath = "https://raw.githubusercontent.com/KhronosGroup/OpenCL-Registry/main/xml/cl.xml"

    print('Looking for orphan definitions in ' + specpath)

    spec = parse_xml(specpath)

    REQUIRE_PREFIXES = (
        'feature/require',
        'extensions/extension/require',
    )

    orphan_commands = 0
    orphan_enums = 0
    orphan_types = 0

    # Check commands
    used_commands = set()
    for prefix in REQUIRE_PREFIXES:
        for cmd in spec.findall(prefix + '/command'):
            used_commands.add(cmd.get('name'))
    for cmdname in spec.findall('commands/command/proto/name'):
        if cmdname.text not in used_commands:
            orphan_commands += 1
            print("Command '{}' is defined but not used in any core version or extension!".format(cmdname.text))

    # Check enums
    used_enums = set()
    for prefix in REQUIRE_PREFIXES:
        for enum in spec.findall(prefix + '/enum'):
            used_enums.add(enum.get('name'))
    for enum in spec.findall('enums/enum'):
        if enum.get('name') not in used_enums:
            orphan_enums += 1
            print("Enum '{}' is defined but not used in any core version or extension!".format(enum.get('name')))
    
    # Check types
    used_types = set()
    for prefix in REQUIRE_PREFIXES:
        for ty in spec.findall(prefix + '/type'):
            used_types.add(ty.get('name'))
    for ty in spec.findall('types/type'):
        cat = ty.get('category')
        if cat == 'define':
            name = ty.findall('name')[0].text
        else:
            name = ty.get('name')
        if name not in used_types:
            orphan_types += 1
            print("Type '{}' is defined but not used in any core version or extension!".format(name))

    print()
    print("Found {} orphan commands.".format(orphan_commands))
    print("Found {} orphan enums.".format(orphan_enums))
    print("Found {} orphan types.".format(orphan_types))

    if orphan_commands != 0 or orphan_enums != 0 or orphan_types != 0:
        sys.exit(1)
    else:
        sys.exit(0)

