# encoding: utf-8
#
# Take a wiki document and extract the template options of the specified template
#
# {{Infobox person
# |name    = Casanova
# |image   = Casanova_self_portrait.jpg
# |caption = A self portrait of  Casanova
# |website =
# }}
#
# and returns the template data in json...
#
# {"name":"Casanova","caption":"A self portrait of  Casanova","website":"","image":"Casanova_self_portrait.jpg"}
#
# This file takes two arguments: filename, and template name
# ex: ./template_extractor test.wiki "Infobox person"
#
require File.join(File.dirname(__FILE__),'../init.rb')
require 'json'

class TemplateExtractor < WikiCloth::Parser

  def initialize(args = {})
    @templates = []
    super(args)
    to_html # parse the document
  end

  def extract(name)
    ret = []
    @templates.each do |template|
      ret << template[:data] if template[:name] == name
    end
    ret.length == 1 ? ret.first : ret
  end

  link_for do |url,text|
    text.blank? ? url : text
  end

  include_resource do |resource,options|
    data = {}
    options.each do |opt|
      data[opt[:name]] = opt[:value]
    end
    @templates << { :name => resource, :data => data }
    ""
  end

end

wiki_data = ""
if ARGV[0] && File.exists?(ARGV[0])
  wiki_data = File.read(ARGV[0])
else
  wiki_data = <<END_OF_DOC
{{Infobox person
|name    = Casanova
|image   = Casanova_self_portrait.jpg
|caption = A self portrait of  Casanova
|website =
}}
END_OF_DOC
end

@wiki = TemplateExtractor.new(:data => wiki_data)
puts @wiki.extract(ARGV[1] ? ARGV[1] : "Infobox person").to_json
