# -*- encoding: utf-8 -*-
require 'rubygems' unless Object.const_defined?(:Gem)
require File.dirname(__FILE__) + "/lib/boson/more/version"

Gem::Specification.new do |s|
  s.name        = "boson-more"
  s.version     = Boson::More::VERSION
  s.authors     = ["Gabriel Horner"]
  s.email       = "gabriel.horner@gmail.com"
  s.homepage    = "http://github.com/cldwalker/boson-more"
  s.summary = "boson2 plugins"
  s.description =  "A collection of boson plugins that can be mixed and matched"
  s.required_rubygems_version = ">= 1.3.6"
  s.add_dependency 'boson', '>= 1.3.0'
  s.add_development_dependency 'mocha', '~> 0.10.4'
  s.add_development_dependency 'bacon', '>= 1.1.0'
  s.add_development_dependency 'mocha-on-bacon'
  s.add_development_dependency 'bacon-bits'
  s.add_development_dependency 'hirb'
  s.add_development_dependency 'alias'
  s.files = Dir.glob(%w[{lib,test}/**/*.rb bin/* [A-Z]*.{txt,rdoc} ext/**/*.{rb,c} **/deps.rip]) + %w{Rakefile .gemspec .travis.yml}
  s.extra_rdoc_files = ["README.md", "LICENSE.txt"]
  s.license = 'MIT'
end
