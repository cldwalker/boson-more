require 'boson/view'
require 'boson/pipe'
require 'boson/pipes'
require 'boson/more_scientist'

module Boson
  class OptionCommand
    BASIC_OPTIONS.update(
      :delete_options=>{:type=>:array, :desc=>'Deletes global options starting with given strings' },
      :usage_options=>{:type=>:string, :desc=>"Render options to pass to usage/help"},
      :render=> {:type=>:boolean, :desc=>"Toggle a command's default rendering behavior"})
    PIPE_OPTIONS = {
      :sort=>{:type=>:string, :desc=>"Sort by given field"},
      :reverse_sort=>{:type=>:boolean, :desc=>"Reverse a given sort"},
      :query=>{:type=>:hash, :desc=>"Queries fields given field:search pairs"},
      :pipes=>{:alias=>'P', :type=>:array, :desc=>"Pipe to commands sequentially"}
    } #:nodoc:

    RENDER_OPTIONS = {
      :fields=>{:type=>:array, :desc=>"Displays fields in the order given"},
      :class=>{:type=>:string, :desc=>"Hirb helper class which renders"},
      :max_width=>{:type=>:numeric, :desc=>"Max width of a table"},
      :vertical=>{:type=>:boolean, :desc=>"Display a vertical table"},
    } #:nodoc:

    # Adds render and pipe global options
    # For more about pipe and render options see Pipe and View respectively.
    # === Toggling Views With the Basic Global Option --render
    # One of the more important global options is --render. This option toggles the rendering of a command's
    # output done with View and Hirb[http://github.com/cldwalker/hirb].
    #
    # Here's a simple example of toggling Hirb's table view:
    #   # Defined in a library file:
    #   #@options {}
    #   def list(options={})
    #     [1,2,3]
    #   end
    #
    #   Using it in irb:
    #   >> list
    #   => [1,2,3]
    #   >> list '-r'  # or list --render
    #   +-------+
    #   | value |
    #   +-------+
    #   | 1     |
    #   | 2     |
    #   | 3     |
    #   +-------+
    #   3 rows in set
    #   => true
    #  == Additional config keys for the main repo config
    #  [:render_options] Hash of render options available to all option commands to be passed to a Hirb view (see View). Since
    # this merges with default render options, it's possible to override default render options.
    #  [:no_auto_render] When set, turns off commandline auto-rendering of a command's output. Default is false.
    module ClassRender

      def default_options
        default_pipe_options.merge(default_render_options.merge(BASIC_OPTIONS))
      end

      def default_pipe_options
        @default_pipe_options ||= PIPE_OPTIONS.merge Pipe.pipe_options
      end

      def default_render_options
        @default_render_options ||= RENDER_OPTIONS.merge Boson.repo.config[:render_options] || {}
      end

      def delete_non_render_options(opt)
        opt.delete_if {|k,v| BASIC_OPTIONS.keys.include?(k) }
      end
    end
    extend ClassRender

    module Render
      def option_parser
        @option_parser ||= @command.render_options ? OptionParser.new(all_global_options) :
          self.class.default_option_parser
      end

      def all_global_options
        OptionParser.make_mergeable! @command.render_options
        render_opts = Util.recursive_hash_merge(@command.render_options, Util.deep_copy(self.class.default_render_options))
        merged_opts = Util.recursive_hash_merge Util.deep_copy(self.class.default_pipe_options), render_opts
        opts = Util.recursive_hash_merge merged_opts, Util.deep_copy(BASIC_OPTIONS)
        set_global_option_defaults opts
      end

      def set_global_option_defaults(opts)
        if !opts[:fields].key?(:values)
          if opts[:fields][:default]
            opts[:fields][:values] = opts[:fields][:default]
          else
            if opts[:change_fields] && (changed = opts[:change_fields][:default])
              opts[:fields][:values] = changed.is_a?(Array) ? changed : changed.values
            end
            opts[:fields][:values] ||= opts[:headers][:default].keys if opts[:headers] && opts[:headers][:default]
          end
          opts[:fields][:enum] = false if opts[:fields][:values] && !opts[:fields].key?(:enum)
        end
        if opts[:fields][:values]
          opts[:sort][:values] ||= opts[:fields][:values]
          opts[:query][:keys] ||= opts[:fields][:values]
          opts[:query][:default_keys] ||= "*"
        end
        opts
      end
    end
    include Render
  end

  module Scientist
    # * Before a method returns its value, it pipes its return value through pipe commands if pipe options are specified. See Pipe.
    # * Methods can have any number of optional views associated with them via global render options (see View). Views can be toggled
    #   on/off with the global option --render (see OptionCommand).
    module Render
      attr_accessor :rendered, :render

      def after_parse
        (@global_options[:delete_options] || []).map {|e|
          @global_options.keys.map {|k| k.to_s }.grep(/^#{e}/)
        }.flatten.each {|e| @global_options.delete(e.to_sym) }
      end

      def process_result(result)
        if (@rendered = can_render?)
          if @global_options.key?(:class) || @global_options.key?(:method)
            result = Pipe.scientist_process(result, @global_options, :config=>@command.config, :args=>@args, :options=>@current_options)
          end
          View.render(result, OptionCommand.delete_non_render_options(@global_options.dup), false)
        else
          Pipe.scientist_process(result, @global_options, :config=>@command.config, :args=>@args, :options=>@current_options)
        end
      rescue StandardError
        raise Scientist::Error, $!.message, $!.backtrace
      end

      def can_render?
        render.nil? ? command_renders? : render
      end

      def command_renders?
        (!!@command.render_options ^ @global_options[:render]) && !Pipe.any_no_render_pipes?(@global_options)
      end

      def run_pretend_option(args)
        super
        @rendered = true if @global_options[:pretend]
      end

      def help_options
        super.tap do |opts|
          if @global_options[:usage_options]
            opts << "--render_options=#{@global_options[:usage_options]}"
          end
          opts
        end
      end
    end
    extend Render
  end

  class Command
    module ScienceClassMethods
      attr_accessor :all_option_commands

      def create(name, library)
        super.tap do |obj|
          if @all_option_commands && !%w{get method_missing}.include?(name)
            obj.make_option_command(library)
          end
        end
      end
    end
    extend ScienceClassMethods

    module Science
      # Option parser for command as defined by @render_options.
      def render_option_parser
        option_command? ? Boson::Scientist.option_command(self).option_parser : nil
      end

      def make_option_command(lib=library)
        @option_command = true
        @args = [['*args']] unless args(lib) || arg_size
      end

      def option_command?
        super || render_options
      end
    end
    include Science
  end

  # [*:render_options*] Hash of rendering options to pass to OptionParser. If the key :output_class is passed,
  #                     that class's Hirb config will serve as defaults for this rendering hash.
  class Command
    attr_accessor :render_options

    module Science
      def after_initialize(hash)
        if hash[:render_options] && (@render_options = hash.delete(:render_options))[:output_class]
          @render_options = Util.recursive_hash_merge View.class_config(@render_options[:output_class]), @render_options
        end
        super
      end
    end
  end

  if defined? BinRunner
    class BinRunner < BareRunner
      GLOBAL_OPTIONS.update(
        option_commands: {
          :type=>:boolean,
          :desc=>"Toggles on all commands to be defined as option commands"
        },
        render: {:type=>:boolean,
          :desc=>"Renders a Hirb view from result of command without options"}
      )

      # [:render] Toggles the auto-rendering done for commands that don't have views. Doesn't affect commands that already have views.
      #           Default is false. Also see Auto Rendering section below.
      #
      # ==== Auto Rendering
      # Commands that don't have views (defined via render_options) have their return value auto-rendered as a view as follows:
      # * nil,false and true aren't rendered
      # * arrays are rendered with Hirb's tables
      # * non-arrays are printed with inspect()
      # * Any of these cases can be toggled to render/not render with the global option :render
      # To turn off auto-rendering by default, add a :no_auto_render: true entry to the main config.
      module Science
        def init
          Command.all_option_commands = true if @options[:option_commands]
          super
        end

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

        def execute_command(cmd, args)
          render_output super
        end
      end

      class <<self
        include Science
      end
    end
  end

  # Additional method attributes:
  # * render_options: Hash to define an OptionParser object for a command's local/global render options (see View).
  class MethodInspector
    METHODS << :render_options
    METHOD_CLASSES[:render_options] = Hash
    SCRAPEABLE_METHODS << :render_options
  end

  module CommentInspector
    EVAL_ATTRIBUTES << :render_options
  end
end
