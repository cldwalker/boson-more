module Boson
  module RunnerOptions
    # [:verbose] Using this along with :help option shows more help. Also gives verbosity to other actions i.e. loading.
    # [:backtrace] Prints full backtrace on error. Default is false.
    # [:index] Updates index for given libraries allowing you to use them. This is useful if Boson's autodetection of
    #          changed libraries isn't picking up your changes. Since this option has a :bool_default attribute, arguments
    #          passed to this option need to be passed with '=' i.e. '--index=my_lib'.
    # [:load] Explicitly loads a list of libraries separated by commas. Most useful when used with :console option.
    #         Can also be used to explicitly load libraries that aren't being detected automatically.
    # [:pager_toggle] Toggles Hirb's pager in case you'd like to pipe to another command.
    def init
      super
      Boson.verbose = true if options[:verbose]

      if @options.key?(:index)
        Index.update(:verbose=>true, :libraries=>@options[:index])
        @index_updated = true
      elsif !@options[:help] && @command && Boson.can_invoke?(@command)
        Index.update(:verbose=>@options[:verbose])
        @index_updated = true
      end

      Manager.load @options[:load], load_options if @options[:load]
      View.toggle_pager if @options[:pager_toggle]
    end

    def default_libraries
      libs = super
      @options[:unload] ?  libs.select {|e| e !~ /#{@options[:unload]}/} : libs
    end

    def update_index
      unless @index_updated
        super
        @index_updated = true
      end
    end

    def verbose
      @options[:verbose]
    end

    def abort_with(message)
      if verbose || options[:backtrace]
        message += "\nOriginal error: #{$!}\n  #{$!.backtrace.join("\n  ")}"
      end
      super(message)
    end

    def print_usage
      super
      if @options[:verbose]
        Manager.load [Boson::Commands::Core]
        puts "\n\nDEFAULT COMMANDS"
        Boson.invoke :commands, :fields=>["name", "usage", "description"], :description=>false
      end
    end
  end

  if defined? BinRunner
    class BinRunner < BareRunner
      GLOBAL_OPTIONS.update({
        :backtrace=>{:type=>:boolean, :desc=>'Prints full backtrace'},
        :verbose=>{:type=>:boolean, :desc=>"Verbose description of loading libraries, errors or help"},
        :index=>{
          :type=>:array, :desc=>"Libraries to index. Libraries must be passed with '='.",
          :bool_default=>nil, :values=>all_libraries, :regexp=>true, :enum=>false},
        :pager_toggle=>{:type=>:boolean, :desc=>"Toggles Hirb's pager"},
        :unload=>{:type=>:string, :desc=>"Acts as a regular expression to unload default libraries"},
        :load=>{:type=>:array, :values=>all_libraries, :regexp=>true, :enum=>false,
          :desc=>"A comma delimited array of libraries to load"}
      })
      extend RunnerOptions
    end
  end
end
