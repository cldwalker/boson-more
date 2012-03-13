require File.join(File.dirname(__FILE__), 'test_helper')
require 'boson/more_method_inspector'

describe "MethodInspector" do
  describe "commands module with" do
    before_all { eval "module ::Boson::Commands::Zzz; end" }
    before_all { MethodInspector.instance = nil }

    def method_inspector
      MethodInspector.instance
    end

    def parse(string)
      Inspector.enable
      ::Boson::Commands::Zzz.module_eval(string)
      Inspector.disable
      method_inspector.store
    end

    it "not all method attributes set causes method_locations to be set" do
      method_inspector.stubs(:find_method_locations).returns(["/some/path", 10])
      parsed = parse "desc 'yo'; def yo; end; options :yep=>1; def yep; end; " +
        "option :b, :boolean; config :a=>1; desc 'z'; options :a=>1; def az; end"
      parsed[:method_locations].key?('yo').should == true
      parsed[:method_locations].key?('yep').should == true
      parsed[:method_locations].key?('az').should == false
    end

    it "no find_method_locations doesn't set method_locations" do
      method_inspector.stubs(:find_method_locations).returns(nil)
      parse("def bluh; end")[:method_locations].key?('bluh').should == false
    end
  end

  describe "scrape_arguments" do
    def args_from(file_string)
      MethodInspector.scrape_arguments(file_string, "blah")
    end

    it "parses arguments of class method" do
      args_from("    def YAML.blah( filepath )\n").should == [['filepath']]
    end

    it "parses arguments with no spacing" do
      args_from("def bong; end\ndef blah(arg1,arg2='val2')\nend").should == [["arg1"], ['arg2', "'val2'"]]
    end

    it "parses arguments with spacing" do
      args_from("\t def blah(  arg1=val1, arg2 = val2)").should == [["arg1","val1"], ["arg2", "val2"]]
    end

    it "parses arguments without parenthesis" do
      args_from(" def blah arg1, arg2, arg3={}").should == [['arg1'], ['arg2'], ['arg3','{}']]
    end
  end
end
