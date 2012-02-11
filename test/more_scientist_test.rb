describe "Scientist" do
  it "with debug option prints debug" do
    capture_stdout { command_with_args("-v ok") }.should =~ /Arguments.*ok/
  end

  it "with pretend option prints arguments and returns early" do
    Scientist.expects(:process_result).never
    capture_stdout { command_with_args("-p ok") }.should =~ /Arguments.*ok/
  end
end
