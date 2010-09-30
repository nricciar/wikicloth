require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require File.join(File.dirname(__FILE__),'init')

task :default => :test

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
  s.add_dependency 'expression_parser'
  s.add_development_dependency 'test-unit'
  s.add_development_dependency 'activesupport'
end
Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
end

find_file = lambda do |name|
  file_name = lambda {|path| File.join(path, "#{name}.rb")}
  root = $:.detect do |path|
    File.exist?(file_name[path])
  end
  file_name[root] if root
end

TEST_LOADER = find_file['rake/rake_test_loader']
multiruby = lambda do |glob|
  system 'multiruby', TEST_LOADER, *Dir.glob(glob)
end

Rake::TestTask.new(:test) do |test|
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end
