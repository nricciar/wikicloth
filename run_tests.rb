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

# testing fragments
WikiCloth::Parser.context = {:ns => 'Language', :title => 'Java'}
@wiki = WikiParser.new({
  :params => { "PAGENAME" => "Testing123" },
  :data => "<file url='HelloWorld.java' show='true'/>"
})
puts @wiki.to_html

WikiCloth::Parser.context = {:ns => 'Contribution', :title => 'haskellEngineer'}
@wiki = WikiParser.new({
  :params => { "PAGENAME" => "Testing123" },
  :data => "<file url='src/Company/Data.hs'/>"
})
puts @wiki.to_html

WikiCloth::Parser.context = {:ns => 'Concept', :title => 'Local scope'}
@wiki = WikiParser.new({
  :params => { "PAGENAME" => "Testing123" },
  :data => "<fragment url='Program.java/class/Program/method/factorial'/>"
})
puts @wiki.to_html

WikiCloth::Parser.context = {:ns => 'Contribution', :title => 'haskellEngineer'}
@wiki = WikiParser.new({
  :params => { "PAGENAME" => "Testing123" },
  :data => "<file url='/contributions/haskellEngineer/src/Company/Data.hs'/>"
})
puts @wiki.to_html

@wiki = WikiParser.new({
  :params => { "PAGENAME" => "Testing123" },
  :data => "<file url='src/Company/Dude.hs'/>"
})
puts @wiki.to_html

@wiki = WikiParser.new({
  :params => { "PAGENAME" => "Testing123" },
  :data => "<file show=true url='src/Company/Data.hs'/>"
})
puts @wiki.to_html

@wiki = WikiParser.new({
  :params => { "PAGENAME" => "Testing123" },
  :data => "<file name='Company/Data.hs' url='src/Company/Data.hs'/>"
})
puts @wiki.to_html

@wiki = WikiParser.new({
  :params => { "PAGENAME" => "Testing123" },
  :data => "<file name url='src/Company/Data.hs'/>"
})
puts @wiki.to_html

@wiki = WikiParser.new({
  :params => { "PAGENAME" => "Testing123" },
  :data => "<file name='Some/däta:123' url='src/Company/Daewffmwpta.hs'/>"
})
puts @wiki.to_html

@wiki = WikiParser.new({
  :params => { "PAGENAME" => "Testing123" },
  :data => "<file show=true url='src/Company/Dude.hs'/>"
})
puts @wiki.to_html

WikiCloth::Parser.context = {:ns => 'Contribution', :title => 'antlrLexer'}
@wiki = WikiParser.new({
  :params => { "PAGENAME" => "Testing123" },
  :data => '<file url="http://101companies.org/resources/contributions/antlrLexer/src/main/antlr/Company.g"/>'
})
puts @wiki.to_html

@wiki = WikiParser.new({
  :params => { "PAGENAME" => "Testing123" },
  :data => '<file name=name url="http://101companies.org/resources/contributions/antlrLexer/src/main/antlr/Company.g"/>'
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

# test slideshare urls for media tag without download possibility
puts WikiParser.new({
  :data => "<media url='http://www.slideshare.net/rlaemmel/functional-oo-programming'/>"
}).to_html

# test bad urls for media tag
puts WikiParser.new({
    :data => "<media url='https://de.slaökdfmwörmfwrühare.net/rlsfnwrk'>"
}).to_html

WikiCloth::Parser.context = {:ns => 'Contribution', :title => 'haskellTree'}
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

