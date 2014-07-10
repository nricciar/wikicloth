
require 'rubygems'
require 'minitest/autorun'
require 'active_support'
require 'active_support/test_case'
I18n.load_path << File.join(File.dirname(__FILE__),'locales.yml')
require File.join(File.dirname(__FILE__),'../init')
