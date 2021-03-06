require 'bacon'
require 'bacon/bits'
require 'mocha'
require 'mocha-on-bacon'
require 'boson'
require 'fileutils'

# hack to allow multiple tests to run so that all Boson::* constants become top-level
if ARGV.size > 1
  require 'boson/bin_runner'
  require 'boson/more'
end
Object.send :remove_const, :OptionParser
Boson.constants.each {|e| Object.const_set(e, Boson.const_get(e)) unless Object.const_defined?(e) }

ENV['BOSONRC'] = File.dirname(__FILE__) + '/.bosonrc'
ENV['BOSON_HOME'] = File.dirname(__FILE__)

if Boson.respond_to?(:repo)
  # make local so it doesn't pick up my real boson dir
  Boson.repo.dir = File.dirname(__FILE__)
  Boson.instance_variable_set "@repos", [Boson.repo]
end

module TestHelpers
  def assert_error(error, message=nil)
    yield
  rescue error=>e
    e.class.should == error
    e.message.should =~ Regexp.new(message) if message
  else
    nil.should == error
  end

  def reset
    reset_main_object
    reset_boson
  end

  def remove_constant(name, mod=Object)
    mod.send(:remove_const, name) if mod.const_defined?(name, false)
  end

  def reset_main_object
    Boson.send :remove_const, "Universe"
    eval "module ::Boson::Universe; end"
    remove_constant "Blah", Boson::Commands
    Boson.main_object = Object.new
  end

  def reset_boson
    reset_libraries
    Boson.instance_eval("@commands = nil")
  end

  def reset_libraries
    Boson.instance_eval("@libraries = nil")
  end

  def command_exists?(name, bool=true)
    (!!Command.find(name)).should == bool
  end

  def library_loaded?(name, bool=true)
    Manager.loaded?(name).should == bool
  end

  def library(name)
    Boson.library(name)
  end

  def library_has_module(lib, lib_module)
    Manager.loaded?(lib).should == true
    test_lib = library(lib)
    (test_lib.module.is_a?(Module) && (test_lib.module.to_s == lib_module)).should == true
  end

  def library_has_command(lib, command, bool=true)
    (lib = library(lib)) && lib.commands.include?(command).should == bool
  end

  def create_runner(*methods, &block)
    options = methods[-1].is_a?(Hash) ? methods.pop : {}
    library = options[:library] || :Blarg
    remove_constant library

    Object.const_set(library, Class.new(Boson::Runner)).tap do |klass|
      if block
        klass.module_eval(&block)
      else
        methods.each do |meth|
          klass.send(:define_method, meth) { }
        end
      end
    end
  end

  def capture_stdout(&block)
    original_stdout = $stdout
    $stdout = fake = StringIO.new
    begin
      yield
    ensure
      $stdout = original_stdout
    end
    fake.string
  end

  def with_config(options)
    old_config = Boson.config
    Boson.config = Boson.config.merge(options)
    yield
    Boson.config = old_config
  end

  def capture_stderr(&block)
    original_stderr = $stderr
    $stderr = fake = StringIO.new
    begin
      yield
    ensure
      $stderr = original_stderr
    end
    fake.string
  end

  def create_library(libraries, attributes={})
    libraries = [libraries] unless libraries.is_a?(Array)
    libraries.map {|e|
      lib = Library.new({:name=>e}.update(attributes))
      Manager.add_library(lib); lib
    }
  end

  def manager_load(lib, options={})
    @stderr = capture_stderr { Manager.load(lib, options) }
  end

  attr_reader :stderr
end

Bacon::Context.send :include, TestHelpers
