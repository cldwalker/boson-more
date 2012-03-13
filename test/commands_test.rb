require File.join(File.dirname(__FILE__), 'test_helper')
require 'boson/more_commands'
require 'boson/view'

describe "commands" do
  before_all do
      @higgs = Boson.main_object
      if Boson.libraries.size.zero?
        reset_boson
        ancestors = class <<Boson.main_object; self end.ancestors
        # allows running just this test file
        Manager.load BareRunner.default_libraries unless ancestors.include?(Boson::Commands::Core)
      end
  end

  def render_expects(&block)
    Boson::View.expects(:render).with(&block)
  end

  describe "libraries" do
    before_all {
      Boson.libraries << Boson::Library.new(:name=>'blah')
      Boson.libraries << Boson::Library.new(:name=>'another', :module=>"Cool")
    }

    it "lists all when given no argument" do
      render_expects {|*args| args[0].size == Boson.libraries.size }
      @higgs.libraries
    end

    it "searches with a given search field" do
      render_expects {|*args| args[0] == [Boson.library('another')]}
      @higgs.libraries('Cool', :query_fields=>[:module])
    end
  end

  describe "commands" do
    before_all {
      Boson.commands << Command.create('some', Library.new(:name=>'thing'))
      Boson.commands << Command.create('and', Library.new(:name=>'this'))
    }

    it "lists all when given no argument" do
      render_expects {|*args| args[0].size == Boson.commands.size }
      @higgs.commands
    end

    it "searches with a given search field" do
      render_expects {|*args| args[0] == [Command.find('and')]}
      @higgs.commands('this', :query_fields=>[:lib])
    end
  end
end
