require 'test/test_helper'

describe "Loader" do
  describe "load" do
    before { reset }

    describe "module library" do
      def mock_library(*args); end

      it "loads a module library and all its class methods by default" do
        eval %[module ::Harvey; def self.bird; end; def self.eagle; end; end]
        load ::Harvey, :no_mock=>true
        library_has_command('harvey', 'bird')
        library_has_command('harvey', 'eagle')
      end

      it "loads a module library with specified commands" do
        eval %[module ::Peanut; def self.bird; end; def self.eagle; end; end]
        load ::Peanut, :no_mock=>true, :commands=>%w{bird}
        library('peanut').commands.size.should == 1
        library_has_command('peanut', 'bird')
      end

      it "loads a module library as a class" do
        eval %[class ::Mentok; def self.bird; end; def self.eagle; end; end]
        load ::Mentok, :no_mock=>true, :commands=>%w{bird}
        library('mentok').commands.size.should == 1
        library_has_command('mentok', 'bird')
      end
    end
  end
end
