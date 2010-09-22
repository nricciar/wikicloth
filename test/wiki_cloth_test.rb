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
      "{{{def|hello world}}} {{{1}}} {{{test}}} {{{nested|{{{3}}}}}}"
    end
  end
  external_link do |url,text|
    "<a href=\"#{url}\" target=\"_blank\" class=\"exlink\">#{text.blank? ? url : text}</a>"
  end
end

class WikiClothTest < ActiveSupport::TestCase

  test "template params" do
    wiki = WikiParser.new(:data => "{{testparams|test|test=bla|it worked}}\n")
    data = wiki.to_html
    assert data =~ /hello world/
    assert data =~ /test/
    assert data =~ /bla/
    assert data =~ /it worked!/ # nested default param
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
