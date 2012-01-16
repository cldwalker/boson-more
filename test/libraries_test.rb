
describe "Loader" do
  before { Gem.stubs(:loaded_specs).returns({}) }
  describe "config" do
    before { reset }
    it "from inspector attribute config sets command's config" do
      load :blah, :file_string=>"module Blah; config :alias=>'ok'\n; def bling; end; end"
      library('blah').command_object('bling').alias.should == 'ok'
    end
  end
end
