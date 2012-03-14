require 'boson/console'
require File.join(File.dirname(__FILE__), 'test_helper')

describe "repl_runner" do
  def start(hash={})
    Boson.start(hash.merge(:verbose=>false))
  end

  before_all { reset }
  before { ConsoleRunner.instance_eval("@initialized = false") }

  it "loads default libraries and libraries in :console_defaults config" do
    defaults = BareRunner.default_libraries + ['yo']
    with_config(:console_defaults=>['yo']) do
      Manager.expects(:load).with {|*args| args[0] == defaults }
      start
    end
  end

  it "doesn't call init twice" do
    capture_stderr { start }
    ConsoleRunner.expects(:init).never
    start
  end

  it "loads multiple libraries with :libraries option" do
    ConsoleRunner.expects(:init)
    Manager.expects(:load).with([:lib1,:lib2], anything)
    start(:libraries=>[:lib1, :lib2])
  end

  it "autoloader autoloads libraries" do
    start(:autoload_libraries=>true)
    Index.expects(:read)
    Index.expects(:find_library).with('blah').returns('blah')
    Manager.expects(:load).with('blah', anything)
    Boson.main_object.blah
  end
  after_all { FileUtils.rm_r File.dirname(__FILE__)+'/config', :force=>true }

  # TODO: fix
  xdescribe "console options" do
    before_all { reset }

    it "console option starts irb" do
      ConsoleRunner.expects(:start)
      Util.expects(:which).returns("/usr/bin/irb")
      ConsoleRunner.expects(:load_repl).with("/usr/bin/irb")
      start("--console")
    end

    it "console option but no irb found prints error" do
      ConsoleRunner.expects(:start)
      Util.expects(:which).returns(nil)
      ConsoleRunner.expects(:abort).with {|arg| arg[/Console not found/] }
      start '--console'
    end
  end
end
