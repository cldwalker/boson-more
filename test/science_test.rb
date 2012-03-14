require 'boson'
require 'boson/bin_runner'
require 'boson/science'
require 'test/test_helper'

describe "BinRunner" do
  def start(*args)
    BinRunner.start(args)
  end

  # TODO: fix with commands
  xdescribe "options" do
    it "help option and command prints help" do
      capture_stdout { start('-h', 'commands') }.should =~ /^commands/
    end

    it "global option takes value with whitespace" do
      View.expects(:render).with {|*args| args[1][:fields] = %w{f1 f2} }
      start('commands', '-f', 'f1, f2')
    end
  end

  describe "render_output" do
    before { Scientist.rendered = false; BinRunner.instance_eval "@options = {}" }

    it "doesn't render when nil, false or true" do
      View.expects(:render).never
      [nil, false, true].each do |e|
        BinRunner.render_output e
      end
    end

    it "doesn't render when rendered with Scientist" do
      Scientist.rendered = true
      View.expects(:render).never
      BinRunner.render_output 'blah'
    end

    it "render with puts when non-string" do
      View.expects(:render).with('dude', {:method => 'puts'})
      BinRunner.render_output 'dude'
    end

    it "renders with inspect when non-array and non-string" do
      [{:a=>true}, :ok].each do |e|
        View.expects(:puts).with(e.inspect)
        BinRunner.render_output e
      end
    end

    it "renders with inspect when Scientist rendering toggled off with :render" do
      Scientist.global_options = {:render=>true}
      View.expects(:puts).with([1,2].inspect)
      BinRunner.render_output [1,2]
      Scientist.global_options = nil
    end

    it "renders with hirb when array" do
      View.expects(:render_object)
      BinRunner.render_output [1,2,3]
    end
  end

end

__END__
# TODO: Fix undefined render_options
describe "MethodInspector" do
  def parse(string)
    Inspector.enable
    ::Boson::Commands::Zzz.module_eval(string)
    Inspector.disable
    method_inspector.store
  end

  before_all { eval "module ::Boson::Commands::Zzz; end" }

  it "render_options sets render_options" do
    parse("render_options :z=>true; def zee; end")[:render_options].should == {"zee"=>{:z=>true}}
  end
end
