
require 'rubygems'
gem "test-unit", ">= 2.0.5"
require 'active_support'
require 'active_support/test_case'
require 'test/unit'
I18n.load_path << File.join(File.dirname(__FILE__),'locales.yml')
require File.join(File.dirname(__FILE__),'../init')
