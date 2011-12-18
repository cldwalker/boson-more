module Boson
  module PipeRunner
    PIPE = '+'

    # Splits array into array of arrays with given element
    def self.split_array_by(arr, divider)
      arr.inject([[]]) {|results, element|
        (divider == element) ? (results << []) : (results.last << element)
        results
      }
    end

    def parse_args(args)
      @all_args = PipeRunner.split_array_by(args, PIPE)
      args = @all_args[0]
      super(args).tap do |result|
        @all_args[0] = ([result[0]] + Array(result[2])).compact
      end
    end

    def execute_command(command, args)
      @all_args.inject(nil) do |acc, (cmd,*args)|
        args = translate_args(args, acc)
        super(cmd, args)
      end
    end

    def translate_args(args, piped)
      args.unshift piped if piped
      args
    end

    # Commands to executed, in order given by user
    def commands
      @commands ||= @all_args.map {|e| e[0]}
    end
  end

  if defined? BinRunner
    class BinRunner < Runner
      class << self; include PipeRunner; end
    end
  end
end
