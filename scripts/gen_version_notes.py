#!/usr/bin/env python3

# Copyright 2019-2025 The Khronos Group Inc.
# SPDX-License-Identifier: Apache-2.0

from collections import OrderedDict

import argparse
import sys
import os
import urllib
import xml.etree.ElementTree as etree
import urllib.request


def parse_xml(path):
    file = urllib.request.urlopen(path) if path.startswith("http") else open(
        path, 'r')
    with file:
        tree = etree.parse(file)
        return tree


# File Header:
def GetHeader():
    return """// Copyright 2017-2025 The Khronos Group.
// SPDX-License-Identifier: CC-BY-4.0
"""


# File Footer:
def GetFooter():
    return """
"""

def FullNote(name, is_extension, added_in, deprecated_by):
    if is_extension:
        assert deprecated_by == None
        return "\nIMPORTANT: {%s} is provided by the `%s` extension." % (name, added_in)
    else:
        # Four patterns: (1) always present in OpenCL, (2) added after 1.0, (3) in
        # 1.0 but now deprecated, and (4) added after 1.0 but now deprecated.
        if added_in == "1.0" and deprecated_by == None:
            return "\n// Intentionally empty, %s has always been present." % name
        if added_in != "1.0" and deprecated_by == None:
            return "\nIMPORTANT: {%s} is {missing_before} version %s." % (name, added_in)
        if added_in == "1.0" and deprecated_by != None:
            return "\nIMPORTANT: {%s} is {deprecated_by} version %s." % (name, deprecated_by)
        if added_in != "1.0" and deprecated_by != None:
            return "\nIMPORTANT: {%s} is {missing_before} version %s and {deprecated_by} version %s." % (name, added_in, deprecated_by)

def ShortNote(name, is_extension, added_in, deprecated_by):
    if is_extension:
        assert deprecated_by == None
        return "provided by the `%s` extension." % added_in
    else:
        # Four patterns: (1) always present in OpenCL, (2) added after 1.0, (3) in
        # 1.0 but now deprecated, and (4) added after 1.0 but now deprecated.
        if added_in == "1.0" and deprecated_by == None:
            return "// Intentionally empty, %s has always been present." % name
        if added_in != "1.0" and deprecated_by == None:
            return "{missing_before} version %s." % added_in
        if added_in == "1.0" and deprecated_by != None:
            return "{deprecated_by} version %s." % deprecated_by
        if added_in != "1.0" and deprecated_by != None:
            return "{missing_before} version %s and {deprecated_by} version %s." % (added_in, deprecated_by)

# Find feature or extension groups that are parents of a <feature> or
# <extension> <require> <${entry_type}> tag, and then find all the
# ${entry_type} within each hierarchy:
def process_xml(spec, entry_type, note_printer):
    numberOfEntries = 0
    numberOfNewEntries = 0
    numberOfDeprecatedEntries = 0

    # Track the APIs which have already had a version file written, to avoid
    # a couple of cases like CL_DEPTH, which is required by both a core
    # version and an extension.
    seen_apis = set()

    for feature_type in [ 'feature', 'extension' ]:
        for feature in spec.findall(f'.//{feature_type}/require/{entry_type}/../..'):
            for entry in feature.findall(f'.//{entry_type}'):
                name = entry.get('name')
                is_extension = feature_type != 'feature'
                deprecated_by = None

                numberOfEntries += 1
                if feature_type == 'feature':
                    added_in = feature.get('number')

                    # All the groups that this specific API ${entry_type} belongs.
                    categories = spec.findall(
                        './/require[@comment]/%s[@name="%s"]/..' % (entry_type, name))
                    for category in categories:
                        comment = category.get('comment')
                        if "deprecated in OpenCL" in comment:
                            words = comment.split(" ")
                            assert " ".join(words[-4:-1]) == "deprecated in OpenCL"
                            assert deprecated_by == None  # Can't deprecate something twice.
                            deprecated_by = words[-1]
                else:
                    if name in seen_apis:
                        print(f'WARNING: {name} exists as both a core version and extension API in the XML')
                        print('This is not currently handled correctly - only the core version dependency is noted')
                        continue

                    # Extensions do not allow for deprecation
                    added_in = feature.get('name')

                seen_apis.add(name)

                versionFileName = os.path.join(args.directory, name + ".asciidoc")
                with open(versionFileName, 'w') as versionFile:
                    versionFile.write(GetHeader())
                    versionFile.write(note_printer(name, is_extension, added_in, deprecated_by))
                    versionFile.write(GetFooter())

                    numberOfNewEntries += 0 if added_in == "1.0" else 1
                    numberOfDeprecatedEntries += 0 if deprecated_by == None else 1

    print('Found ' + str(numberOfEntries) + ' API ' + entry_type + 's, '
          + str(numberOfNewEntries) + " newer than 1.0, "
          + str(numberOfDeprecatedEntries) + " are deprecated.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument(
        '-registry',
        action='store',
        default='cl.xml',
        help='Use specified registry file instead of cl.xml')
    parser.add_argument(
        '-o',
        action='store',
        dest='directory',
        default='.',
        help='Create target and related files in specified directory')

    args = parser.parse_args()

    specpath = args.registry

    print('Generating version notes from: ' + specpath)

    spec = parse_xml(specpath)

    # Generate the API functions dictionaries:

    process_xml(spec, "command", FullNote)
    process_xml(spec, "enum", ShortNote)
