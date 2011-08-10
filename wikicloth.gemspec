# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'wikicloth/version'

spec = Gem::Specification.new do |s|
  s.name = "wikicloth"
  s.version = WikiCloth::VERSION
  s.author = "David Ricciardi"
  s.email = "nricciar@gmail.com"
  s.homepage = "http://github.com/nricciar/wikicloth"
  s.platform = Gem::Platform::RUBY
  s.summary = "An implementation of the mediawiki markup in ruby"
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = "lib"
  s.description = File.read("README")
  s.has_rdoc = false
  s.extra_rdoc_files = ["README","MIT-LICENSE"]
  s.description = %q{mediawiki parser}
  s.add_dependency 'builder'
  s.add_dependency 'expression_parser'
  s.add_development_dependency 'test-unit'
  s.add_development_dependency 'activesupport'
end
