require 'boson'
require 'boson/bin_runner'
require 'test/test_helper'

describe "BinRunner" do
  describe "at commandline" do
    def aborts_with(regex)
      BinRunner.expects(:abort).with {|e| e[regex] }
      yield
    end

    def start(*args)
      # Hirb.stubs(:enable)
      BinRunner.start(args)
    end

    before {|e|
      BinRunner.instance_variables.each {|e| BinRunner.instance_variable_set(e, nil)}
    }

    before_all { reset }

    it "invalid option value prints error" do
      aborts_with(/Error: no value/) { start("-l") }
    end

    it "load option loads libraries" do
      Manager.expects(:load).with {|*args| args[0][0].is_a?(Module) ? true : args[0][0] == 'blah'}.times(2)
      BinRunner.stubs(:execute_command)
      start('-l', 'blah', 'libraries')
    end

    it "with backtrace option prints backtrace" do
      BinRunner.expects(:autoload_command).returns(false)
      aborts_with(/not found\nOriginal.*runner\.rb:/m) { start("--backtrace", "blah") }
    end
  end
end
