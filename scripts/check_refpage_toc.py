#!/usr/bin/python3
#
# Copyright 2016-2024 The Khronos Group Inc.
#
# SPDX-License-Identifier: Apache-2.0

# check_refpage_toc.py - validate the hand-written refpage category index
# against the actual generated refpages.
#
# Usage: check_refpage_toc.py -toctail path -refpages path

import argparse
import io
import os
import re
import sys
from reflib import loadFile

#Inputs:
#
#man/toctail
#    Contains the category index, which is a fragment (not valid HTML) with lines like
#
#        ...<a href="enums.html" target="pagedisplay">Enumerated Types</a>...
#        ...<a href="clGetPlatformIDs.html" target="pagedisplay">clGetPlatformIDs</a>
#
#    This should ideally refer to all generated refpages and aliases of them.
#
#    With the .html removed, the link text will sometimes be the same as the
#    page name; sometimes be an alias to the page name; and sometimes just be
#    explanatory text.
#
#    We already know that some extension appendices do not appear in the
#    category index; they do appear in the alphabetical index.
#
#    Unfortunately, some of the anchor text contains HTML constructs or text
#    more complex than just a name or a sequence of words. Probably will need
#    special handling.
#
#    There are the following duplicates in the link text;
#
#cl_image_format
#cl_khr_d3d10_sharing
#cl_khr_d3d11_sharing
#cl_khr_dx9_media_sharing
#cl_khr_gl_event
#cl_khr_gl_sharing
#clamp   (different targets, commonClamp / clamp_integer)
#max     (different targets, commonMax / integerMax)
#min     (different targets, commonMin / integerMin)
#
#    In general this is fine, so long as the targets are identical. The
#    handful of different targets are also generally fine ATM and can
#    be put on an exception list if needed.
#
#gen/refpage
#    Contains the extracted and static (from man/static/) refpage source
#    files, named e.g. 'clGetPlatformIDs.txt', and the Apache rewrites for
#    aliases in 'rewritebody', which look like
#
#        RewriteRule ^CL_VERSION_1_0.html$ preprocessorDirectives.html
#
#    Combined, these make up the complete refpage set. We would like every
#    page and alias to be the category index (even more ideally, they would
#    be searchable in Antora, etc.)
#
#    rewritebody describes the actual aliases, and ideally should match the
#    aliases in man/toctail.
#
#Comparison process:
#    toctail - RE match to page names and descriptions.
#    Construct dual index from page name to description(s) and vice-versa
#    (handle aliased descriptions somehow).
#
#    refpages - scan directory for all .txt files and construct
#    name -> name mapping.
#    Scan rewritebody (or better, emit it as a Python dictionary as well) and
#    construct alias -> name mapping.
#    Note that .txt files are 'actual' refpages.

if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument('-tocfile', action='store', dest='tocfile',
                        default='man/toctail',
                        help='Set the ToC file (default man/toctail')
    parser.add_argument('-refpages', action='store', dest='refpages',
                        default='generated/refpage',
                        help='Set path to generate refpage directory (default generated/refpage)')

    results = parser.parse_args()
    errcount = 0

    # Scan ToC
    file, _ = loadFile(results.tocfile)
    if file is None:
        write(f'Cannot open ToC file {results.tocfile}')
        sys.exit(1)

    FIND_TOC_LINK_RE = re.compile(r'.*href="(?P<link>[^"]+)[^>]+>(?P<text>[^<]+)</a>')

    # ToC links. Each entry is a set of link texts mapping to that refpage name
    toclinks = {}

    # ToC texts. Each entry is a set of refpage names described with that text
    toctext = {}

    for line in file:
        # Extract ToC link, if present
        match = FIND_TOC_LINK_RE.match(line)

        if match is None:
            continue

        link = match.group('link')
        text = match.group('text')

        # Strip .html suffix
        if link[-5:] != '.html':
            print(f'{results.tocfile} contains non-.html link {link}: {line}')
            continue
        link = link[:-5]

        #if text[-5:] != '.html':
        #    print(f'{rewritefile} contains non-.html rewrite to {text}: {line}')
        #    continue
        #text = text[:-5]

        if link not in toclinks:
            toclinks[link] = set()
        toclinks[link].add(text)

        if text not in toctext:
            toctext[text] = set()
        toctext[text].add(link)

    print(f'{len(toclinks)} links in ToC, {len(toctext)} link-texts')
    for link, texts in toclinks.items():
        if len(texts) > 1:
            print(f'link {link} -> {len(texts)} distinct texts: {texts}')

    for text, links in toctext.items():
        if len(links) > 1:
            print(f'text {text} -> {len(links)} distinct links: {links}')

    # Scan refpages

    # Actual pages - each entry is a set of aliases that rewrite to that page
    refpages = {}

    # Page aliases - each entry is the page name they are rewritten to
    refaliases = {}

    # Collect files in the refpage directory
    for file in os.listdir(results.refpages):
        if file.endswith('.txt'):
            # Strip '.txt' leaving the API name
            pagename = file[:-4]
            refpages[pagename] = set()

    # Collect aliases from the rewritebody file
    rewritefile = results.refpages + '/rewritebody'
    file, _ = loadFile(rewritefile)
    if file is None:
        write(f'Cannot open HTML rewrite file {rewritefile}')
        sys.exit(1)

    FIND_REWRITE_LINK_RE = re.compile(r'.*\^(?P<alias>[^$]+)\$ +(?P<page>[^ ]+)')

    for line in file:
        # Extract rewrite directive, if present
        # Remove trailing newline
        match = FIND_REWRITE_LINK_RE.match(line.rstrip())

        if match is None:
            continue

        alias = match.group('alias')
        page = match.group('page')

        if alias[-5:] != '.html':
            print(f'{rewritefile} contains non-.html rewrite from {alias}: {line}')
            continue

        if page[-5:] != '.html':
            print(f'{rewritefile} contains non-.html rewrite to {page}: {line}')
            continue

        # Now strip .html suffixes
        alias = alias[:-5]
        page = page[:-5]

        # Track alias -> page rewrites
        if alias in refaliases:
            print(f'{rewritefile} contains multiple rewrites of {alias}: {line}')
            errcount += 1
        else:
            refaliases[alias] = page

        # Track all aliases rewriting to a page
        if page not in refpages:
            print(f'{rewritefile} contains rewrite of {alias} to the nonexistent refpage {page}: {line}')
            errcount += 1
        else:
            refpages[page].add(alias)

    #####################################

    # Verify that all .html files in toctail exist and tag whether they are
    # aliases or not.

    for link in sorted(toclinks.keys()):
        if link not in refpages and link not in refaliases:
            print(f'ToC link to {link}.html has no corresponding refpage {link}.txt, or alias to it')
            errcount += 1

    # Verify that all aliases in refpages/ appear in toctail as descriptions.

    for alias in sorted(refaliases.keys()):
        if alias not in toctext:
            print(f'refpage alias {alias} has no link from the ToC, at least with that name')
            errcount += 1

    # Verify that all non-aliased names (.txt files) in refpages appear in
    # toctail as .html files and descriptions.

    for page in sorted(refpages.keys()):
        if page not in toclinks:
            print(f'refpage {page} has no link from the ToC')
            errcount += 1

    print(f'{errcount} errors found')

    # Summarize link text (descriptions) that do not appear as refpage
    # aliases. Most are probably just straight text and fine.
    #
    # Summarize any remaining discrepancies.

    print(f'Found {len(refpages)} reference pages')
    print(f'Found {len(refaliases)} aliases to reference pages')
