# This extension script is taken from the Asciidoctor extensions lab [1], under
# the MIT license [2].
#
# [1] https://github.com/asciidoctor/asciidoctor-extensions-lab/blob/18bdf628f46d9c98920c20413d8d99bf5ea622a8/lib/sectnumoffset-treeprocessor.rb
# [2] https://github.com/asciidoctor/asciidoctor-extensions-lab/blob/18bdf628f46d9c98920c20413d8d99bf5ea622a8/LICENSE.adoc

require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'

include Asciidoctor

Extensions.register do
  # A treeprocessor that increments each level-1 section number by the value of
  # the `sectnumoffset` attribute. The numbers of all subsections will be
  # incremented automatically since those values are calculated dynamically.
  #
  # Run using:
  #
  # asciidoctor -r ./lib/sectnumoffset-treeprocessor.rb -a sectnums -a sectnumoffset=1 lib/sectnumoffset-treeprocessor/sample.adoc
  treeprocessor do
    process do |document|
      if (document.attr? 'sectnums') && (sectnumoffset = (document.attr 'sectnumoffset', 0).to_i) > 0
        ((document.find_by context: :section) || []).each do |sect|
          # FIXME use filter block once Asciidoctor >= 1.5.3 is available
          next unless sect.level == 1
          sect.number += sectnumoffset
        end
      end
      nil
    end
  end
end
