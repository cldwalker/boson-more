require 'boson/alias'
require 'test/test_helper'

# Add library_loaded? and with_config
describe "Manager" do
  def load_library(hash)
    new_attributes = {:name=>hash[:name], :commands=>[], :created_dependencies=>[], :loaded=>true}
    [:module, :commands].each {|e| new_attributes[e] = hash.delete(e) if hash[e] }
    Manager.instance.expects(:call_load_action).returns(Library.new(new_attributes))
    Manager.load([hash[:name]])
  end

  before { reset_boson }

  describe "command aliases" do
    before { eval %[module ::Aquateen; def frylock; end; end] }
    after { Object.send(:remove_const, "Aquateen") }

    it "created with command specific config" do
      with_config(:command_aliases=>{'frylock'=>'fr'}) do
        Manager.instance.expects(:create_instance_aliases).with({"Aquateen"=>{"frylock"=>"fr"}})
        load_library :name=>'aquateen', :commands=>['frylock'], :module=>Aquateen
        library_loaded? 'aquateen'
      end
    end

    it "created with config command_aliases" do
      with_config(:command_aliases=>{"frylock"=>"fr"}) do
        Manager.instance.expects(:create_instance_aliases).with({"Aquateen"=>{"frylock"=>"fr"}})
        load_library :name=>'aquateen', :commands=>['frylock'], :module=>Aquateen
        library_loaded? 'aquateen'
      end
    end

    it "not created and warns for commands with no module" do
      with_config(:command_aliases=>{'frylock'=>'fr'}) do
        capture_stderr {
          load_library(:name=>'aquateen', :commands=>['frylock'])
        }.should =~ /No aliases/
        library_loaded? 'aquateen'
        Aquateen.method_defined?(:fr).should == false
      end
    end
  end
end

describe "Loader" do
  describe "load" do
    before { reset }
    it "loads a library and creates its class commands" do
      with_config(:libraries=>{"blah"=>{:class_commands=>{"bling"=>"Blah.bling", "Blah"=>['hmm']}}}) do
        load :blah, :file_string=>"module Blah; def self.bling; end; def self.hmm; end; end"
        command_exists? 'bling'
        command_exists? 'hmm'
      end
    end
  end
end
