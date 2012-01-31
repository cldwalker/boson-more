module Boson
  class OptionParser
    module MoreOptionParser
      # Given options to pass to OptionParser.new, this method parses ARGV and
      # returns the remaining arguments and a hash of parsed options. This is
      # useful for scripts outside of Boson.
      def parse(options, args=ARGV)
        @opt_parser ||= new(options)
        parsed_options = @opt_parser.parse(args)
        [@opt_parser.non_opts, parsed_options]
      end

      # Usage string summarizing options defined in parse
      def usage
        @opt_parser.to_s
      end

      def make_mergeable!(opts)
        opts.each {|k,v|
          if !v.is_a?(Hash) && !v.is_a?(Symbol)
            opts[k] = {:default=>v}
          end
        }
      end
    end
    extend MoreOptionParser
  end
end
