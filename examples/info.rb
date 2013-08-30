require File.join(File.dirname(__FILE__),'../init.rb')
if ARGV[0] && File.exists?(ARGV[0])
  data = File.read(ARGV[0])
else
  data = "== Section ==
dqwd
=== Some Stuff ===
dqwdq
==== More stuff ====

== Foo ==

dqdq

"
end

wiki = WikiCloth::Parser.new(:data => data)
#puts wiki.to_html
#puts "..."
puts wiki.sections.first.children.length

# puts "Internal Links: #{wiki.internal_links.size}"
# puts "External Links: #{wiki.external_links.size}"
# puts "References:     #{wiki.references.size}"
# puts "Categories:     #{wiki.categories.size} [#{wiki.categories.join(",")}]"
# puts "Languages:      #{wiki.languages.size} [#{wiki.languages.keys.join(",")}]"
