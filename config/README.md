# OpenCL Asciidoctor Configuration Files

## Macros

The macros in `spec-macros.rb` and `spec-macros/extension.rb` are described
in the "Vulkan Documentation and Extensions: Procedures and Conventions"
document (see the [Vulkan
registry](http://www.khronos.org/registry/vulkan/)).

## Support for Math

katex_replace.rb inserts KaTeX `<script>` tags from `math.js` for HTML5, and
properly passes through math which has `\begin{}\/end{}` delimiters instead
of $$\[\]\(\).

For PDF builds, asciidoctor-mathematical is used to generate
PNG images which are incorporated into the output.

`mathjax-asciidoc.conf`, `mathjax-docbook.conf`, and `mathjax.js` are still
used to support MathJax for documents using the older asciidoc toolchain.
`mathjax-docbook.conf` is heavily conditionalized depending on whether the
final output format (which should be described in the a2x-format variable)
is `pdf` or not, since Docbook passes through math differently to dblatex
vs. the XHTML stylesheets.
