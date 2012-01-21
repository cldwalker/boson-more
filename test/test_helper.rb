require 'bacon'
require 'bacon/bits'
require 'mocha'
require 'mocha-on-bacon'
require 'boson'
require 'fileutils'
Object.send :remove_const, :OptionParser
Boson.constants.each {|e| Object.const_set(e, Boson.const_get(e)) unless Object.const_defined?(e) }
ENV['BOSONRC'] = File.dirname(__FILE__) + '/.bosonrc'
ENV['BOSON_HOME'] = File.dirname(__FILE__)

# make local so it doesn't pick up my real boson dir
Boson.repo.dir = File.dirname(__FILE__)
Boson.instance_variable_set "@repos", [Boson.repo]
