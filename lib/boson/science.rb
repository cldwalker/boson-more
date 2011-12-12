require 'boson/scientist'
require 'boson/option_command'
require 'boson/pipe'
require 'boson/pipes'

module Boson
  class Command
    module Science
      # Option parser for command as defined by @render_options.
      def render_option_parser
        option_command? ? Boson::Scientist.option_command(self).option_parser : nil
      end
    end
    include Science
  end

  class Manager
    module Science
      def redefine_commands(lib, commands)
        accepted,_ = super
        accepted.each {|cmd| Scientist.redefine_command(lib.namespace_object, cmd) }
      end
    end

    class << self; include Science; end
  end

  class BinRunner
    module Science
      def render_output(output)
        if (!Scientist.rendered && !View.silent_object?(output)) ^ @options[:render] ^
          Boson.repo.config[:no_auto_render]
            opts = output.is_a?(String) ? {:method=>'puts'} :
              {:inspect=>!output.is_a?(Array) || (Scientist.global_options || {})[:render] }
            View.render output, opts
        end
      end

      def allowed_argument_error?(err, cmd, args)
        err.class == OptionCommand::CommandArgumentError || super
      end

      def execute_command
        render_output super
      end
    end

    class <<self
      include Science
    end
  end
end
