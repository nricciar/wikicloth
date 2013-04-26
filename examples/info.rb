require File.join(File.dirname(__FILE__),'../init.rb')
if ARGV[0] && File.exists?(ARGV[0])
  data = File.read(ARGV[0])
else
  data = "* Lecture [[Script:Introduction_to_functional_programming|Introduction]]"
  data +=  "\n[[Script:Introduction_to_functional_programming]] ... [[Language:Bar]]"
end

wiki = WikiCloth::Parser.new(:data => data)
puts wiki.to_html

puts "Internal Links: #{wiki.internal_links.size}"
puts "External Links: #{wiki.external_links.size}"
puts "References:     #{wiki.references.size}"
puts "Categories:     #{wiki.categories.size} [#{wiki.categories.join(",")}]"
puts "Languages:      #{wiki.languages.size} [#{wiki.languages.keys.join(",")}]"
