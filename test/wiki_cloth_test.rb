# encoding: utf-8
require File.expand_path(File.join(File.dirname(__FILE__),'test_helper'))

class WikiParser < WikiCloth::Parser
  url_for do |page|
    page
  end

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
    when "tablebegin"
      "<table>"
    when "tablemid"
      "<tr><td>test</td></tr>"
    when "tableend"
      "</table>"
    end
  end
  external_link do |url,text|
    "<a href=\"#{url}\" target=\"_blank\" class=\"exlink\">#{text.blank? ? url : text}</a>"
  end
end

class WikiClothTest < ActiveSupport::TestCase

  test "math tag" do
    wiki = WikiParser.new(:data => "<math>1-\frac{k}{|E(G_j)|}</math>")
    begin
      data = wiki.to_html
      assert true
    rescue
      assert false
    end
  end

  test "links and references" do
    wiki = WikiCloth::Parser.new(:data => File.open(File.join(File.dirname(__FILE__), '../sample_documents/george_washington.wiki'), READ_MODE) { |f| f.read })
    data = wiki.to_html
    assert wiki.external_links.size == 38
    assert wiki.references.size == 76
    assert wiki.internal_links.size == 322
    assert wiki.categories.size == 27
    assert wiki.languages.size == 101
  end
 
  test "links with imbedded links" do
    wiki = WikiParser.new(:data => "[[Datei:Schulze and Gerard 01.jpg|miniatur|Klaus Schulze während eines Konzerts mit [[Lisa Gerrard]]]] hello world")
    data = wiki.to_html
    assert data =~ /Lisa Gerrard/
  end
 
  test "links with trailing letters" do
    wiki = WikiParser.new(:data => "[[test]]s [[rawr]]alot [[some]]thi.ng [[a]] space")
    data = wiki.to_html
    assert data =~ /tests/
    assert data =~ /href="test"/
    assert data =~ /rawralot/
    assert data !~ /something/
    assert data !~ /aspace/
  end

  test "piped links with trailing letters" do
    wiki = WikiParser.new(:data => "[[a|b]]c [[b|c]]d<nowiki>e</nowiki>")
    data = wiki.to_html
    assert data =~ /bc/
    assert data =~ /href="a"/
    assert data =~ /cd/
    assert data !~ /cde/
  end

  test "Embedded images with no explicit title" do
    wiki = WikiParser.new(:data => "[[Image:Rectangular coordinates.svg|left|thumb|250px]]")
    test = true
    begin
      data = wiki.to_html
    rescue
      test = false 
    end
    assert test == true
  end

  test "First item in list not created when list is preceded by a heading" do
    wiki = WikiParser.new(:data => "=Heading=\n* One\n* Two\n* Three")
    data = wiki.to_html
    assert data !~ /\*/
  end

  test "behavior switch should not show up in the html output" do
    wiki = WikiParser.new(:data => "__NOTOC__hello world")
    data = wiki.to_html
    assert data !~ /TOC/
  end

  test "template vars should not be parsed inside a pre tag" do
    wiki = WikiCloth::Parser.new(:data => "<pre>{{{1}}}</pre>")
    data = wiki.to_html
    assert data =~ /&#123;&#123;&#123;1&#125;&#125;&#125;/
  end

  test "[[ links ]] should not work inside pre tags" do
    data = <<EOS 
Now instead of calling WikiCloth::Parser directly call your new class.

<pre>  @wiki = WikiParser.new({
    :params => { "PAGENAME" => "Testing123" },
    :data => "[[test]] {{hello|world}} From {{ PAGENAME }} -- [www.google.com]"
  })

  @wiki.to_html</pre>
EOS
    wiki = WikiCloth::Parser.new(:data => data)
    data = wiki.to_html
    assert data !~ /href/
    assert data !~ /\{/
    assert data !~ /\]/
  end

  test "auto pre at end of document" do
    wiki = WikiParser.new(:data => "test\n\n hello\n world\nend")
    data = wiki.to_html
    assert data =~ /hello/
    assert data =~ /world/

    wiki = WikiParser.new(:data => "test\n\n hello\n world")
    data = wiki.to_html
    assert data =~ /hello/
    assert data =~ /world/
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
  
  test "table spanning template" do
    wiki = WikiParser.new(:data => "{{tablebegin}}{{tablemid}}{{tableend}}")
    data = wiki.to_html
    
    assert data =~ /test/
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
    assert_equal count.to_s, "6"
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
  end

  test "nowiki and code tags" do
    wiki = WikiParser.new(:data => "<nowiki>{{test}}</nowiki><code>{{test}}</code>{{nowiki}}\n")
    data = wiki.to_html
    assert !(data =~ /busted/)
    assert data =~ /hello world/
  end

  test "disable edit stuff" do
    wiki = WikiParser.new(:data => "= Hallo =")
    data = wiki.to_html
    if RUBY_VERSION == "1.8.7"
      assert_equal data, "\n<p><h1><span class=\"editsection\">&#91;<a href=\"?section=Hallo\" title=\"Edit section: Hallo\">edit</a>&#93;</span> <span class=\"mw-headline\" id=\"Hallo\"><a name=\"Hallo\">Hallo</a></span></h1></p>"
    else
      assert_equal data, "\n<p><h1><span class=\"editsection\">&#91;<a href=\"?section=Hallo\" title=\"Edit section: Hallo\">edit</a>&#93;</span> <span id=\"Hallo\" class=\"mw-headline\"><a name=\"Hallo\">Hallo</a></span></h1></p>"
    end

    data = wiki.to_html(:noedit => true)
    if RUBY_VERSION == "1.8.7"
      assert_equal data, "\n<p><h1><span class=\"mw-headline\" id=\"Hallo\"><a name=\"Hallo\">Hallo</a></span></h1></p>"
    else
      assert_equal data, "\n<p><h1><span id=\"Hallo\" class=\"mw-headline\"><a name=\"Hallo\">Hallo</a></span></h1></p>"
    end
  end

  test "render toc" do
    wiki = WikiCloth::WikiCloth.new({:data => "=A=\n=B=\n=C=\n=D="})
    data = wiki.render
    assert data =~ /A/
  end

  test "table after paragraph" do
    wiki = WikiCloth::WikiCloth.new({:data => "A\n{|style=""\n|\n|}"})
    data = wiki.render
    assert data =~ /table/
  end

  test "pre trailing newlines" do
    wiki = WikiCloth::WikiCloth.new({:data => "A\n B\n\n\n\nC"})
    data = wiki.render
    assert_equal data, "\n<p>A\n</p>\n<p><pre> B\n</pre>\n</p>\n\n\n\n<p>C</p>"
  end

  test "pre at eof" do
    wiki = WikiCloth::WikiCloth.new({:data => "A\n B\n"})
    data = wiki.render
    assert_equal data, "\n<p>A\n</p>\n<p><pre> B\n</pre>\n</p>"
  end

  test "empty item in toc" do
    wiki = WikiCloth::WikiCloth.new({:data => "__TOC__\n=A="})
    data = wiki.render
    if RUBY_VERSION == "1.8.7"
      assert_equal data, "\n<p><table id=\"toc\" class=\"toc\" summary=\"Contents\"><tr><td><div style=\"font-weight:bold\">Table of Contents</div><ul></li><li><a href=\"#A\">A</a></li></ul></td></tr></table>\n<h1><span class=\"editsection\">&#91;<a href=\"?section=A\" title=\"Edit section: A\">edit</a>&#93;</span> <span class=\"mw-headline\" id=\"A\"><a name=\"A\">A</a></span></h1></p>"
    else
      assert_equal data, "\n<p><table id=\"toc\" class=\"toc\" summary=\"Contents\"><tr><td><div style=\"font-weight:bold\">Table of Contents</div><ul></li><li><a href=\"#A\">A</a></li></ul></td></tr></table>\n<h1><span class=\"editsection\">&#91;<a href=\"?section=A\" title=\"Edit section: A\">edit</a>&#93;</span> <span id=\"A\" class=\"mw-headline\"><a name=\"A\">A</a></span></h1></p>"
    end
  end

  test "pre at beginning" do
    wiki = WikiCloth::WikiCloth.new({:data => " A"})
    data = wiki.render
    assert_equal data, "\n\n<p><pre> A\n</pre>\n</p>"
  end

  test "toc declared as list" do
    wiki = WikiCloth::WikiCloth.new({:data => "__TOC__\n=A=\n==B==\n===C==="})
    data = wiki.render
    if RUBY_VERSION == "1.8.7"
      assert_equal data, "\n<p><table id=\"toc\" class=\"toc\" summary=\"Contents\"><tr><td><div style=\"font-weight:bold\">Table of Contents</div><ul></li><li><a href=\"#A\">A</a><ul><li><a href=\"#B\">B</a><ul><li><a href=\"#C\">C</a></li></ul></ul></ul></td></tr></table>\n<h1><span class=\"editsection\">&#91;<a href=\"?section=A\" title=\"Edit section: A\">edit</a>&#93;</span> <span class=\"mw-headline\" id=\"A\"><a name=\"A\">A</a></span></h1>\n<h2><span class=\"editsection\">&#91;<a href=\"?section=B\" title=\"Edit section: B\">edit</a>&#93;</span> <span class=\"mw-headline\" id=\"B\"><a name=\"B\">B</a></span></h2>\n<h3><span class=\"editsection\">&#91;<a href=\"?section=C\" title=\"Edit section: C\">edit</a>&#93;</span> <span class=\"mw-headline\" id=\"C\"><a name=\"C\">C</a></span></h3></p>"
    else
      assert_equal data, "\n<p><table id=\"toc\" class=\"toc\" summary=\"Contents\"><tr><td><div style=\"font-weight:bold\">Table of Contents</div><ul></li><li><a href=\"#A\">A</a><ul><li><a href=\"#B\">B</a><ul><li><a href=\"#C\">C</a></li></ul></ul></ul></td></tr></table>\n<h1><span class=\"editsection\">&#91;<a href=\"?section=A\" title=\"Edit section: A\">edit</a>&#93;</span> <span id=\"A\" class=\"mw-headline\"><a name=\"A\">A</a></span></h1>\n<h2><span class=\"editsection\">&#91;<a href=\"?section=B\" title=\"Edit section: B\">edit</a>&#93;</span> <span id=\"B\" class=\"mw-headline\"><a name=\"B\">B</a></span></h2>\n<h3><span class=\"editsection\">&#91;<a href=\"?section=C\" title=\"Edit section: C\">edit</a>&#93;</span> <span id=\"C\" class=\"mw-headline\"><a name=\"C\">C</a></span></h3></p>"
    end
  end

  test "toc numbered" do
    wiki = WikiCloth::WikiCloth.new({:data => "=A=\n=B=\n==C==\n==D==\n===E===\n===F===\n====G====\n====H====\n==I==\n=J=\n=K=\n===L===\n===M===\n====N====\n====O===="})
    data = wiki.render(:noedit => true, :toc_numbered => true)
    if RUBY_VERSION == "1.8.7"
      assert_equal data, "\n<p><table id=\"toc\" class=\"toc\" summary=\"Contents\"><tr><td><div style=\"font-weight:bold\">Table of Contents</div><ul></li><li><a href=\"#A\">1 A</a></li><li><a href=\"#B\">2 B</a><ul><li><a href=\"#C\">2.1 C</a></li><li><a href=\"#D\">2.2 D</a><ul><li><a href=\"#E\">2.2.1 E</a></li><li><a href=\"#F\">2.2.2 F</a><ul><li><a href=\"#G\">2.2.2.1 G</a></li><li><a href=\"#H\">2.2.2.2 H</a></li></ul></ul><li><a href=\"#I\">2.3 I</a></li></ul><li><a href=\"#J\">3 J</a></li><li><a href=\"#K\">4 K</a><ul><ul><li><a href=\"#L\">4.1 L</a></li><li><a href=\"#M\">4.2 M</a><ul><li><a href=\"#N\">4.2.1 N</a></li><li><a href=\"#O\">4.2.2 O</a></li></ul></ul></ul></ul></td></tr></table><h1><span class=\"mw-headline\" id=\"A\"><a name=\"A\">A</a></span></h1>\n<h1><span class=\"mw-headline\" id=\"B\"><a name=\"B\">B</a></span></h1>\n<h2><span class=\"mw-headline\" id=\"C\"><a name=\"C\">C</a></span></h2>\n<h2><span class=\"mw-headline\" id=\"D\"><a name=\"D\">D</a></span></h2>\n<h3><span class=\"mw-headline\" id=\"E\"><a name=\"E\">E</a></span></h3>\n<h3><span class=\"mw-headline\" id=\"F\"><a name=\"F\">F</a></span></h3>\n<h4><span class=\"mw-headline\" id=\"G\"><a name=\"G\">G</a></span></h4>\n<h4><span class=\"mw-headline\" id=\"H\"><a name=\"H\">H</a></span></h4>\n<h2><span class=\"mw-headline\" id=\"I\"><a name=\"I\">I</a></span></h2>\n<h1><span class=\"mw-headline\" id=\"J\"><a name=\"J\">J</a></span></h1>\n<h1><span class=\"mw-headline\" id=\"K\"><a name=\"K\">K</a></span></h1>\n<h3><span class=\"mw-headline\" id=\"L\"><a name=\"L\">L</a></span></h3>\n<h3><span class=\"mw-headline\" id=\"M\"><a name=\"M\">M</a></span></h3>\n<h4><span class=\"mw-headline\" id=\"N\"><a name=\"N\">N</a></span></h4>\n<h4><span class=\"mw-headline\" id=\"O\"><a name=\"O\">O</a></span></h4></p>"
    else
      assert_equal data, "\n<p><table id=\"toc\" class=\"toc\" summary=\"Contents\"><tr><td><div style=\"font-weight:bold\">Table of Contents</div><ul></li><li><a href=\"#A\">1 A</a></li><li><a href=\"#B\">2 B</a><ul><li><a href=\"#C\">2.1 C</a></li><li><a href=\"#D\">2.2 D</a><ul><li><a href=\"#E\">2.2.1 E</a></li><li><a href=\"#F\">2.2.2 F</a><ul><li><a href=\"#G\">2.2.2.1 G</a></li><li><a href=\"#H\">2.2.2.2 H</a></li></ul></ul><li><a href=\"#I\">2.3 I</a></li></ul><li><a href=\"#J\">3 J</a></li><li><a href=\"#K\">4 K</a><ul><ul><li><a href=\"#L\">4.1 L</a></li><li><a href=\"#M\">4.2 M</a><ul><li><a href=\"#N\">4.2.1 N</a></li><li><a href=\"#O\">4.2.2 O</a></li></ul></ul></ul></ul></td></tr></table><h1><span id=\"A\" class=\"mw-headline\"><a name=\"A\">A</a></span></h1>\n<h1><span id=\"B\" class=\"mw-headline\"><a name=\"B\">B</a></span></h1>\n<h2><span id=\"C\" class=\"mw-headline\"><a name=\"C\">C</a></span></h2>\n<h2><span id=\"D\" class=\"mw-headline\"><a name=\"D\">D</a></span></h2>\n<h3><span id=\"E\" class=\"mw-headline\"><a name=\"E\">E</a></span></h3>\n<h3><span id=\"F\" class=\"mw-headline\"><a name=\"F\">F</a></span></h3>\n<h4><span id=\"G\" class=\"mw-headline\"><a name=\"G\">G</a></span></h4>\n<h4><span id=\"H\" class=\"mw-headline\"><a name=\"H\">H</a></span></h4>\n<h2><span id=\"I\" class=\"mw-headline\"><a name=\"I\">I</a></span></h2>\n<h1><span id=\"J\" class=\"mw-headline\"><a name=\"J\">J</a></span></h1>\n<h1><span id=\"K\" class=\"mw-headline\"><a name=\"K\">K</a></span></h1>\n<h3><span id=\"L\" class=\"mw-headline\"><a name=\"L\">L</a></span></h3>\n<h3><span id=\"M\" class=\"mw-headline\"><a name=\"M\">M</a></span></h3>\n<h4><span id=\"N\" class=\"mw-headline\"><a name=\"N\">N</a></span></h4>\n<h4><span id=\"O\" class=\"mw-headline\"><a name=\"O\">O</a></span></h4></p>"
    end
  end
end
