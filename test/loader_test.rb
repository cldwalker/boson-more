describe "Loader" do
  it "loads a library and creates its class commands" do
    with_config(:libraries=>{"blah"=>{:class_commands=>{"bling"=>"Blah.bling", "Blah"=>['hmm']}}}) do
      load :blah, :file_string=>"module Blah; def self.bling; end; def self.hmm; end; end"
      command_exists? 'bling'
      command_exists? 'hmm'
    end
  end

  it "loads a module library and all its class methods by default" do
    eval %[module ::Harvey; def self.bird; end; def self.eagle; end; end]
    load ::Harvey, :no_mock=>true
    library_has_command('harvey', 'bird')
    library_has_command('harvey', 'eagle')
  end

  it "prints error when nonexistent" do
    capture_stderr { load('blah') }.should =~ /Library blah did not/
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

  it "hash from inspector recursively merged with user's config" do
    with_config(:libraries=>{'blah'=>{:commands=>{'blung'=>{:args=>[], :options=>{:sort=>'this'}}}}}) do
      CommentInspector.expects(:scrape).returns({:options=>{:fields=>['this']}})
      load :blah, :file_string=>"module Blah; def blung; end; end"
      library('blah').command_object('blung').options.should == {:fields=>["this"], :sort=>"this"}
    end
  end
end
