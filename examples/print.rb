require File.join(File.dirname(__FILE__),'../init.rb')
if ARGV[0] && File.exists?(ARGV[0])
  data = File.read(ARGV[0])
else
  data = "[[ this ]] is a [[ link ]] and another [http://www.google.com Google] but they should be disabled"
end

# Disables all links in the document for printing
class PrettyPrint < WikiCloth::Parser

  external_link do |url,text|
    text.nil? ? url : "#{text} (#{url})"
  end

  link_for do |page,text|
    text.nil? ? page : text
  end

end

# load file into custom parser and render without 
# section edit links
puts PrettyPrint.new(:data => data).to_html(:noedit => true)
