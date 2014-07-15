require 'rubygems'
require 'rake'
require File.join(File.dirname(__FILE__),'init')

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.pattern = 'test/*_test.rb'
  test.verbose = true
end

require 'simplecov'
desc "Code coverage detail"
task :simplecov do
  ENV['COVERAGE'] = "true"
  Rake::Task['spec'].execute
end

task :default => :test

require 'rdoc/task'
RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "wikicloth #{WikiCloth::VERSION}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('MIT-LICENSE')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
