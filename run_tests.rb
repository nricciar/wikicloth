# encoding: UTF-8

require File.join(File.dirname(__FILE__),'init')
include WikiCloth

class WikiParser < WikiCloth::Parser

  include_resource do |resource,options|
    case resource
    when "date"
      Time.now.to_s
    else
      params[resource].nil? ? "" : params[resource]
    end
  end

  url_for do |page|
    "javascript:alert('You clicked on: #{page}');"
  end

  link_attributes_for do |page|
    { :href => url_for(page) }
  end

end

@wiki = WikiCloth::Parser.new({
  :data => "\n  {{test}}\n\n<nowiki>{{test}}</nowiki> ''Hello {{test}}!''\n",
  :params => { "test" => "World" } })
puts @wiki.to_html

@wiki = WikiParser.new({
  :params => { "PAGENAME" => "Testing123" },
  :data => "[[Hello World]] From {{ PAGENAME }} on {{ date }}"
})
puts @wiki.to_html

# test youtube urls for media tag
puts WikiParser.new({
   :data => "<media url=\"http://www.youtube.com/watch?v=AWIO3nPInzg\">"
}).to_html

# test slideshare urls for media tag
puts WikiParser.new({
   :data => "<media url='https://de.slideshare.net/rlaemmel/patterns-19905697'>"
}).to_html

# test bad urls for media tag
puts WikiParser.new({
    :data => "<media url='https://de.slaökdfmwörmfwrühare.net/rlsfnwrk'>"
}).to_html

Dir.glob("sample_documents/*.wiki").each do |x|

  start_time = Time.now
  out_name = "#{x}.html"
  data = File.open(x, READ_MODE) { |x| x.read }

  tmp = WikiCloth::Parser.new({
    :data => data,
    :params => { "PAGENAME" => "HelloWorld" }
  })
  out = tmp.to_html
  out = "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\" dir=\"ltr\"><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" /><link rel=\"stylesheet\" href=\"default.css\" type=\"text/css\" /></head><body>#{out}</body></html>"

  File.open(out_name, "w") { |x| x.write(out) }
  end_time = Time.now
  puts "#{out_name}: Completed (#{end_time - start_time} sec) | External Links: #{tmp.external_links.size} -- References: #{tmp.references.size}"

end

