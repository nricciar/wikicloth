require File.join(File.dirname(__FILE__),'test_helper')

class WikiParser < WikiCloth::Parser
  template do |template|
    case template
    when "noinclude"
      "<noinclude>hello world</noinclude><includeonly>testing</includeonly>"
    when "test"
      "busted"
    when "nowiki"
      "hello world"
    when "testparams"
      "{{{def|hello world}}} {{{1}}} {{{test}}} {{{nested|{{{2}}}}}}"
    when "moreparamtest"
      "{{{{{test|bla}}|wtf}}}"
    when "loop"
      "{{loop}}"
    end
  end
  external_link do |url,text|
    "<a href=\"#{url}\" target=\"_blank\" class=\"exlink\">#{text.blank? ? url : text}</a>"
  end
end

class WikiClothTest < ActiveSupport::TestCase

  test "links and references" do
    wiki = WikiCloth::Parser.new(:data => File.read(File.join(File.dirname(__FILE__), '../sample_documents/george_washington.wiki')))
    data = wiki.to_html
    assert wiki.external_links.size == 62
    assert wiki.references.size == 76
    assert wiki.internal_links.size == 560
  end

  test "template params" do
    wiki = WikiParser.new(:data => "{{testparams|test|test=bla|it worked|bla=whoo}}\n")
    data = wiki.to_html
    assert data =~ /hello world/
    assert data =~ /test/
    assert data =~ /bla/
    assert data =~ /it worked/ # nested default param

    wiki = WikiParser.new(:data => "{{moreparamtest|p=othervar}}")
    data = wiki.to_html
    assert data =~ /wtf/

    wiki = WikiParser.new(:data => "{{moreparamtest|p=othervar|busted=whoo}}")
    data = wiki.to_html
    assert data =~ /whoo/
  end

  test "horizontal rule" do
    wiki = WikiParser.new(:data => "----\n")
    data = wiki.to_html
    assert data =~ /hr/
  end

  test "template loops" do
    wiki = WikiParser.new(:data => "{{#iferror:{{loop}}|loop detected|wtf}}")
    data = wiki.to_html
    assert data =~ /loop detected/
  end

  test "input with no newline" do
    wiki = WikiParser.new(:data => "{{test}}")
    data = wiki.to_html
    assert data =~ /busted/
  end

  test "lists" do
    wiki = WikiParser.new(:data => "* item 1\n* item 2\n* item 3\n")
    data = wiki.to_html
    assert data =~ /ul/
    count = 0
    # should == 6.. 3 <li>'s and 3 </li>'s
    data.gsub(/li/) { |ret| 
      count += 1 
      ret
    }
    assert count == 6
  end

  test "noinclude and includeonly tags" do
    wiki = WikiParser.new(:data => "<noinclude>main page</noinclude><includeonly>never seen</includeonly>{{noinclude}}\n")
    data = wiki.to_html
    assert data =~ /testing/
    assert data =~ /main page/
    assert !(data =~ /never seen/)
    assert !(data =~ /hello world/)
  end

  test "bold/italics" do
    wiki = WikiParser.new(:data => "test ''testing'' '''123''' '''''echo'''''\n")
    data = wiki.to_html
    assert data =~ /<i>testing<\/i>/
    assert data =~ /<b>123<\/b>/
    assert data =~ /<b><i>echo<\/i><\/b>/
  end

  test "sanitize html" do
    wiki = WikiParser.new(:data => "<script type=\"text/javascript\" src=\"bla.js\"></script>\n<a href=\"test.html\" onmouseover=\"alert('hello world');\">test</a>\n")
    data = wiki.to_html
    assert !(data =~ /<script/)
    assert !(data =~ /onmouseover/)
    assert data =~ /exlink/
  end

  test "nowiki and code tags" do
    wiki = WikiParser.new(:data => "<nowiki>{{test}}</nowiki><code>{{test}}</code>{{nowiki}}\n")
    data = wiki.to_html
    assert !(data =~ /busted/)
    assert data =~ /hello world/
  end

end
