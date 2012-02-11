module Boson
  # Any command with options comes with basic global options. For example '-hv'
  # on an option command prints a help summarizing global and local options.
  # Another basic global option is --pretend. This option displays what global
  # options have been parsed and the actual arguments to be passed to a
  # command if executed. For example:
  #
  #   # Define this command in a library
  #   options :level=>:numeric, :verbose=>:boolean
  #   def foo(*args)
  #     args
  #   end
  #
  #   irb>> foo 'testin -p -l=1'
  #   Arguments: ["testin", {:level=>1}]
  #   Global options: {:pretend=>true}
  #
  # If a global option conflicts with a local option, the local option takes
  # precedence. You can get around this by passing global options after a '-'.
  # For example, if the global option -h (--help) conflicts with a local -h
  # (--force):
  #   foo 'arg1 -v -f - -f=f1,f2'
  #   # is the same as
  #   foo 'arg1 -v --fields=f1,f2 -f'
  class OptionCommand
    BASIC_OPTIONS.update(
      :verbose=>{:type=>:boolean, :desc=>"Increase verbosity for help, errors, etc."},
      :pretend=>{:type=>:boolean,
        :desc=>"Display what a command would execute without executing it"}
    )
  end
  module Scientist
    module MoreScientist
      def during_analyze(&block)
        run_pretend_option(@args)
        super unless @global_options[:pretend]
      end

      def analyze(*)
        super
      rescue OptionCommand::CommandArgumentError
        run_pretend_option(@args ||= [])
        return if !@global_options[:pretend] &&
          run_verbose_help(option_command, @original_args)
        raise unless @global_options[:pretend]
      end

      private
      def run_verbose_help(option_command, original_args)
        global_opts = option_command.parse_global_options(original_args)
        if global_opts[:help] && global_opts[:verbose]
          @global_options = global_opts
          run_help_option @command
          return true
        end
        false
      end

      def run_pretend_option(args)
        if @global_options[:verbose] || @global_options[:pretend]
          puts "Arguments: #{args.inspect}",
            "Global options: #{@global_options.inspect}"
        end
      end
    end
    extend MoreScientist
  end
end
