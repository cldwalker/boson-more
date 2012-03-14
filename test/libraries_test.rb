require 'test_helper'

describe "Loader" do
  before { Gem.stubs(:loaded_specs).returns({}) }
  describe "config" do
    before { reset }

    # if this test fails, other exists? using methods fail
    it "from callback recursively merges with user's config" do
      with_config(:libraries=>{'blah'=>{:commands=>{'bling'=>{:desc=>'bling', :options=>{:num=>3}}}}}) do
        File.stubs(:exists?).returns(true)
        load :blah, :file_string=> "module Blah; def self.config; {:commands=>{'blang'=>{:alias=>'ba'}, " +
          "'bling'=>{:options=>{:verbose=>:boolean}}}}; end; end"
        library('blah').command_object('bling').options.should == {:verbose=>:boolean, :num=>3}
        library('blah').command_object('bling').desc.should == 'bling'
        library('blah').command_object('blang').alias.should == 'ba'
      end
    end

    it "non-hash from inspector overridden by user's config" do
      with_config(:libraries=>{'blah'=>{:commands=>{'bling'=>{:desc=>'already'}}}}) do
        load :blah, :file_string=>"module Blah; #from file\ndef bling; end; end"
        library('blah').command_object('bling').desc.should == 'already'
      end
    end

    it "from inspector attribute config sets command's config" do
      load :blah, :file_string=>"module Blah; config :alias=>'ok'\n; def bling; end; end"
      library('blah').command_object('bling').alias.should == 'ok'
    end
  end

  describe "load" do
    before { reset }
    it "calls included callback" do
      capture_stdout {
        load :blah, :file_string=>"module Blah; def self.included(mod); puts 'included blah'; end; def blah; end; end"
      }.should =~ /included blah/
    end

    it "calls after_included callback" do
      capture_stdout {
        load :blah, :file_string=>"module Blah; def self.after_included; puts 'yo'; end; end"
      }.should == "yo\n"
    end

    it "prints error if library module conflicts with top level constant/module" do
      capture_stderr {
        load :blah, :file_string=>"module Object; def self.blah; end; end"
      }.should =~ /conflict.*'Object'/
      library_loaded?('blah')
    end
  end

  after_all { FileUtils.rm_r File.dirname(__FILE__)+'/commands/', :force=>true }
end
