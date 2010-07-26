# -*- encoding: utf-8 -*-
 
files = %W{
MIT-LICENSE
Rakefile
run_tests.rb
wikicloth.gemspec
README
test/wiki_cloth_test.rb
test/test_helper.rb
init.rb
lib
lib/wiki_buffer
lib/wiki_buffer/html_element.rb
lib/wiki_buffer/var.rb
lib/wiki_buffer/link.rb
lib/wiki_buffer/table.rb
lib/core_ext.rb
lib/wiki_cloth.rb
lib/wikicloth.rb
lib/wiki_buffer.rb
lib/wiki_link_handler.rb
tasks/wikicloth_tasks.rake
sample_documents
sample_documents/wiki_tables.wiki
sample_documents/tv.wiki
sample_documents/elements.wiki
sample_documents/air_force_one.wiki
sample_documents/cheatsheet.wiki
sample_documents/default.css
sample_documents/george_washington.wiki
sample_documents/wiki.png
sample_documents/random.wiki
sample_documents/pipe_trick.wiki
sample_documents/lists.wiki
sample_documents/images.wiki
}
 
test_files = %W{
run_tests.rb
test/test_helper.rb
test/wiki_cloth_test.rb
}
 
Gem::Specification.new do |s|
  s.name = %q{wikicloth}
  s.version = '0.1.3'
 
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["nricciar"]
  s.email = "nricciar@gmail.com"
  s.date = %q{2009-07-16}
  s.description = %q{mediawiki parser}
  s.extra_rdoc_files = %W{README MIT-LICENSE}
  s.files = files
  s.has_rdoc = true
  s.homepage = %q{http://code.google.com/p/wikicloth/}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{wikicloth}
  s.rubygems_version = %q{1.3.0}
  s.summary = %q{An implementation of the mediawiki markup in ruby}
  s.test_files = test_files
 
  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2
  end
end
