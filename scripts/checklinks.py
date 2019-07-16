#!/usr/bin/python3
#
# Copyright (c) 2013-2019 The Khronos Group Inc.
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

import argparse
import os
import re

if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument('-d', action='store', dest='directory',
                        default='../api',
                        help='Directory containing files to check')
    parser.add_argument('--unlinked', action='store_true',
                        help='Check for unlinked APIs and enums (may have false positives!)')

    args = parser.parse_args()

    links = set()
    anchors = set()

    for filename in os.listdir(args.directory):
        filename = args.directory + '/' + filename
        sourcefile = open(filename, 'r')
        sourcetext = sourcefile.read()
        sourcefile.close()

        # We're not going to check API links.
        #filelinks = re.findall(r"{((cl\w+)|(CL\w+))}", sourcetext)
        filelinks = re.findall(r"{((CL\w+))}", sourcetext)
        fileanchors = re.findall(r"{((cl\w+)|(CL\w+))_anchor}", sourcetext)

        filelinks = [re.sub(r"_anchor\b", "", link[0]) for link in filelinks]
        fileanchors = [anchor[0] for anchor in fileanchors]

        links = links.union(set(filelinks) - set(fileanchors))
        anchors = anchors.union(set(fileanchors))

        #print("=== " + filename)
        #print("links:")
        #print(' '.join(filelinks))
        #print("anchors:")
        #print(' '.join(fileanchors))

        if args.unlinked:
            # Look for APIs and enums that do not begin with:
            #   { = asciidoctor attribute link
            #   character = middle of word
            #   < = asciidoctor link
            #   ' = refpage description
            #   / = proto include
            fileunlinkedapi = sorted(list(set(re.findall(r"[^{\w<'/](cl[A-Z]\w+)\b[^'](?!.')", sourcetext))))
            fileunlinkedenums = sorted(list(set(re.findall("r[^{\w<](CL_\w+)", sourcetext))))

            if len(fileunlinkedapi) != 0:
                print("unlinked APIs in " + filename + ":\n\t" + '\n\t'.join(fileunlinkedapi))

            if len(fileunlinkedenums) != 0:
                print("unlinked enums in " + filename + ":\n\t" + '\n\t'.join(fileunlinkedenums))

    linkswithoutanchors = sorted(list(links - anchors))
    anchorswithoutlinks = sorted(list(anchors - links))

    print("links without anchors:\n\t" + '\n\t'.join(linkswithoutanchors))
    #print("anchors without links:\n\t" + '\n\t'.join(anchorswithoutlinks))
