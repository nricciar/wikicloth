require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'init'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the wikicloth plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the wikicloth plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'WikiCloth'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

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
  s.add_dependency 'math_parser'
end
Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
end
