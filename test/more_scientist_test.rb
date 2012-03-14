require 'test/test_helper'
require 'boson/more_scientist'

describe "Scientist" do
  before_all {
    Boson.in_shell = nil
    eval <<-EOF
    module Blah
      def blah(arg1, options={})
        [arg1, options]
      end
      def splat_blah(*args)
        args
      end
      def default_blah(arg1, arg2=default, options={})
        [arg1, arg2, options]
      end
      def default; 'some default'; end
      def default_option(options={})
        options
      end
    end
    EOF
    @opt_cmd = Object.new.extend Blah
  }

  def command_with_args(*args)
    command({:args=>[['arg1'],['options', {}]]}, args)
  end

  def command(hash, args)
    hash = {:name=>'blah', :lib=>'bling', :options=>{:force=>:boolean, :level=>2}}.merge(hash)
    @cmd = Command.new hash
    @cmd.instance_variable_set("@file_parsed_args", true) if hash[:file_parsed_args]
    Scientist.redefine_command(@opt_cmd, @cmd)
    @opt_cmd.send(hash[:name], *args)
  end

  it "with debug option prints debug" do
    capture_stdout { command_with_args("-v ok") }.should =~ /Arguments.*ok/
  end

  it "with pretend option prints arguments and returns early" do
    Scientist.expects(:process_result).never
    capture_stdout { command_with_args("-p ok") }.should =~ /Arguments.*ok/
  end
end
