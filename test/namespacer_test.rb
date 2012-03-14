require 'boson'
require 'boson/namespacer'
require File.join(File.dirname(__FILE__), 'test_helper')

describe "Loader" do
  def load_namespace_library
    Manager.load([Boson::Commands::Namespace])
  end

  before { Gem.stubs(:loaded_specs).returns({}) }
  describe "config" do
    before { reset }
    it "from callback overridden by user's config" do
      with_config(:libraries=>{'blih'=>{:namespace=>false}}) do
        load :blih, :file_string=>"module Blah; def self.config; {:namespace=>'bling'}; end; end"
        library('blih').namespace.should == false
      end
    end
  end

  describe "load" do
    before { reset }

    it "namespaces a library that has a method conflict" do
      load('blah', :file_string=>"module Blah; def chwhat; end; end")
      capture_stderr {
        load('chwhat2', :file_string=>"module Chwhat2; def chwhat; end; end")
      }.should =~ /conflict.*chwhat.*chwhat2/
      library_has_command('namespace', 'chwhat2')
      library_has_command('chwhat2', 'chwhat')
    end
  end

  describe "library with namespace" do
    before_all { reset_main_object }
    before { reset_boson }

    it "loads and defaults to library name" do
      with_config(:libraries=>{'blang'=>{:namespace=>true}}) do
        load 'blang', :file_string=>"module Blang; def bling; end; end"
        library_has_command('blang', 'bling')
      end
    end

    it "loads with config namespace" do
      with_config(:libraries=>{'blung'=>{:namespace=>'dope'}}) do
        load 'blung', :file_string=>"module Blung; def bling; end; end"
        library_has_command('blung', 'bling')
        library('blung').commands.size.should == 1
      end
    end

    it "prints error if namespace conflicts with existing commands" do
      eval "module ::Conflict; def self.bleng; end; end"
      load Conflict, :no_mock=>true
      with_config(:libraries=>{'bleng'=>{:namespace=>true}}) do
        capture_stderr {
          load 'bleng', :file_string=>"module Bleng; def bling; end; end"
        }.should =~ /conflict.*bleng/
      end
    end
  end
end
