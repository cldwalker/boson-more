require 'boson'
require 'boson/science'
require 'boson/view'
require File.join(File.dirname(__FILE__), 'test_helper')

# Now in science.rb
describe "Scientist" do
  before_all {
    Boson.in_shell = nil
    eval <<-EOF
    module Blah
      def blah(arg1, options={})
        [arg1, options]
      end
      def splat_blah(*args)
        args
      end
      def default_blah(arg1, arg2=default, options={})
        [arg1, arg2, options]
      end
      def default; 'some default'; end
      def default_option(options={})
        options
      end
    end
    EOF
    @opt_cmd = Object.new.extend Blah
  }

  def command(hash, args)
    hash = {:name=>'blah', :lib=>'bling', :options=>{:force=>:boolean, :level=>2}}.merge(hash)
    @cmd = Command.new hash
    @cmd.instance_variable_set("@file_parsed_args", true) if hash[:file_parsed_args]
    Scientist.redefine_command(@opt_cmd, @cmd)
    @opt_cmd.send(hash[:name], *args)
  end

  def command_with_arg_size(*args)
    command({:args=>2}, args)
  end

  def command_with_args(*args)
    command({:args=>[['arg1'],['options', {}]]}, args)
  end

  def basic_command(hash, args)
    command({:name=>'splat_blah', :args=>'*'}.merge(hash), args)
  end

  def command_with_splat_args(*args)
    command({:name=>'splat_blah', :args=>'*'}, args)
  end

  def command_with_arg_defaults(*args)
    arg_defaults = [%w{arg1}, %w{arg2 default}, %w{options {}}]
    command({:name=>'default_blah', :file_parsed_args=>true, :args=>arg_defaults}, args)
  end

  def args_are_equal(args, array)
    command_with_args(*args).should == array
    command_with_arg_size(*args).should == array
    command_with_splat_args(*args).should == array
  end

  def all_commands
    [:command_with_args, :command_with_arg_size, :command_with_splat_args]
  end

  describe "command" do
    describe "prints error" do
      it "with unexpected error in render" do
        Scientist.expects(:can_render?).raises("unexpected")
        capture_stderr { command_with_args('a1') }.should =~ /Error.*unexpected/
      end
    end
  end

  def command_with_render(*args)
    basic_command({:render_options=>{:fields=>{:values=>['f1', 'f2']}} }, args)
  end

  def render_expected(options=nil)
    View.expects(:render).with(anything, options || anything, false)
  end

  describe "render" do
    it "called for command with render_options" do
      render_expected
      command_with_render('1')
    end

    it "called for command without render_options and --render" do
      render_expected
      command_with_args('--render 1')
    end

    it "not called for command with render_options and --render" do
      Boson.expects(:invoke).never
      command_with_render('--render 1')
    end

    it "not called for command without render_options" do
      Boson.expects(:invoke).never
      command_with_args('1')
    end
  end

  describe "command renders" do
    it "with basic render options" do
      render_expected :fields => ['f1', 'f2']
      command_with_render("--fields f1,f2 ab")
    end

    it "without non-render options" do
      render_expected :fields=>['f1']
      Scientist.expects(:can_render?).returns(true)
      args = ["--render --fields f1 ab"]
      basic_command({:render_options=>{:fields=>{:values=>['f1', 'f2']}} }, args)
    end

    it "with user-defined render options" do
      render_expected :fields=>['f1'], :foo=>true
      args = ["--foo --fields f1 ab"]
      basic_command({:render_options=>{:foo=>:boolean, :fields=>{:values=>['f1', 'f2']}} }, args)
    end

    it "with non-hash user-defined render options" do
      render_expected :fields=>['f1'], :foo=>true
      args = ["--foo --fields f1 ab"]
      basic_command({:render_options=>{:foo=>:boolean, :fields=>%w{f1 f2 f3}} }, args)
    end
  end

  it "optionless command renders" do
    render_expected :fields=>['f1']
    command({:args=>2, :options=>nil, :render_options=>{:fields=>:array}}, ["--fields f1 ab ok"])
  end

  describe "global options:" do
    def local_and_global(*args)
      Scientist.stubs(:can_render?).returns(false) # turn off rendering caused by :render_options
      @non_opts = basic_command(@command_options, args)
      @non_opts.slice!(-1,1) << Scientist.global_options
    end

    before_all {
      @command_options = {:options=>{:do=>:boolean, :foo=>:boolean},
      :render_options=>{:dude=>:boolean}}
      @expected_non_opts = [[], ['doh'], ['doh'], [:doh]]
    }

    it "local option overrides global one" do
      ['-d', 'doh -d','-d doh', [:doh, '-d']].each_with_index do |args, i|
        local_and_global(*args).should == [{:do=>true}, {}]
        @non_opts.should == @expected_non_opts[i]
      end
    end

    it "global option before local one is valid" do
      args_arr = ['--dude -f', '--dude doh -f', '--dude -f doh', [:doh, '--dude -f']]
      args_arr.each_with_index do |args, i|
        local_and_global(*args).should == [{:foo=>true}, {:dude=>true}]
        @non_opts.should == @expected_non_opts[i]
      end
    end

    it "delete_options deletes global options" do
      local_and_global('--delete_options=r,p -rp -f').should ==
        [{:foo=>true}, {:delete_options=>["r", "p"]}]
    end

    it "global option after local one is invalid" do
      args_arr = ['-f --dude', '-f doh --dude', '-f --dude doh', [:doh, '-f --dude'] ]
      args_arr.each_with_index do |args, i|
        capture_stderr {
          local_and_global(*args).should == [{:foo=>true}, {}]
          @non_opts.should == @expected_non_opts[i]
        }.should =~ /invalid.*dude/
      end
    end

    it "global option after local one and -" do
      local_and_global("doh -r -f - --dude").should == [{:foo=>true}, {:dude=>true, :render=>true}]
    end

    it "conflicting global option after -" do
      local_and_global('doh - -f=1,2').should == [{}, {:fields=>["1", "2"]}]
    end

    it "no options parsed after --" do
      local_and_global('doh -f -- -r').should == [{:foo=>true}, {}]
      local_and_global('doh -- -r -f').should == [{}, {}]
      local_and_global('-- -r -f').should == [{}, {}]
      local_and_global('doh -r -- -f').should == [{}, {:render=>true}]
    end
  end
  after_all { Boson.in_shell = false }
end
