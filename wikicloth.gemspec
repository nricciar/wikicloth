require 'rake'
require File.join(File.dirname(__FILE__),'init')

spec = Gem::Specification.new do |s|
  s.name = "wikicloth"
  s.version = WikiCloth::VERSION
  s.author = "David Ricciardi"
  s.email = "nricciar@gmail.com"
  s.homepage = "http://github.com/nricciar/wikicloth"
  s.platform = Gem::Platform::RUBY
  s.summary = "An implementation of the mediawiki markup in ruby"
  s.files = FileList["{lib,tasks}/**/*"].to_a +
    FileList["sample_documents/*.wiki"].to_a +
    ["init.rb","uninstall.rb","Rakefile","install.rb"]
  s.require_path = "lib"
  s.description = File.read("README")
  s.test_files = FileList["{test}/*.rb"].to_a + ["run_tests.rb"]
  s.has_rdoc = false
  s.extra_rdoc_files = ["README","MIT-LICENSE"]
  s.description = %q{mediawiki parser}
  s.add_dependency 'builder'
  s.add_dependency 'expression_parser'
  s.add_development_dependency 'test-unit'
  s.add_development_dependency 'activesupport'
end
