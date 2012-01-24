describe "Loader" do
  describe "load" do
    before { reset }
    describe "gem library" do
      def mock_library(lib, options={})
        options[:file_string] ||= ''
        File.stubs(:exists?).returns(false)
        GemLibrary.expects(:is_a_gem?).returns(true)
        Util.expects(:safe_require).with { eval options.delete(:file_string) || ''; true}.returns(true)
      end

      it "loads" do
        with_config(:libraries=>{"dude"=>{:module=>'Dude'}}) do
          load "dude", :file_string=>"module ::Dude; def blah; end; end"
          library_has_module('dude', "Dude")
          command_exists?("blah")
        end
      end

      it "with kernel methods loads" do
        load "dude", :file_string=>"module ::Kernel; def dude; end; end"
        library_loaded? 'dude'
        library('dude').module.should == nil
        command_exists?("dude")
      end

      it "prints error when nonexistent" do
        capture_stderr { load('blah') }.should =~ /Library blah did not/
      end

      it "with invalid module prints error" do
        with_config(:libraries=>{"coolio"=>{:module=>"Cool"}}) do
          capture_stderr {
            load('coolio', :file_string=>"module ::Coolio; def coolio; end; end")
          }.should =~ /Unable.*coolio.*No module/
        end
      end
    end
  end
end
