require 'test/test_helper'

describe "Loader" do
  before { Gem.stubs(:loaded_specs).returns({}) }
  describe 'load' do
    before { reset }

    it "loads a library with dependencies" do
      File.stubs(:exists?).returns(true)
      File.stubs(:read).returns("module Water; def water; end; end", "module Oaks; def oaks; end; end")
      with_config(:libraries=>{"water"=>{:dependencies=>"oaks"}}) do
        load 'water', :no_mock=>true
        library_has_module('water', "Boson::Commands::Water")
        library_has_module('oaks', "Boson::Commands::Oaks")
        command_exists?('water')
        command_exists?('oaks')
      end
    end

    it "prints error for library with invalid dependencies" do
      GemLibrary.stubs(:is_a_gem?).returns(true) #mock all as gem libs
      Util.stubs(:safe_require).returns(true)
      with_config(:libraries=>{"water"=>{:dependencies=>"fire"}, "fire"=>{:dependencies=>"man"}}) do
        capture_stderr {
          load('water', :no_mock=>true)
        }.should == "Unable to load library fire. Reason: Can't load dependency man\nUnable to load"+
        " library water. Reason: Can't load dependency fire\n"
      end
    end
  end
end
