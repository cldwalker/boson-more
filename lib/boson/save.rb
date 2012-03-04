require 'boson/namespacer'
require 'boson/repo'
require 'boson/index'
require 'boson/repo_index'

module Boson
  module Save
    def config
      repo.config
    end

    def config=(val)
      repo.config = val
    end

    # The main required repository which defaults to ~/.boson.
    def repo
      @repo ||= Repo.new("#{ENV['BOSON_HOME'] || Dir.home}/.boson")
    end

    # An optional local repository which defaults to ./lib/boson or ./.boson.
    def local_repo
      @local_repo ||= begin
        ignored_dirs = (config[:ignore_directories] || []).map {|e| File.expand_path(e) }
        dir = ["lib/boson", ".boson"].find {|e| File.directory?(e) &&
            File.expand_path(e) != repo.dir && !ignored_dirs.include?(File.expand_path('.')) }
        Repo.new(dir) if dir
      end
    end

    # The array of loaded repositories containing the main repo and possible local and global repos
    def repos
      @repos ||= [repo, local_repo, global_repo].compact
    end

    # Optional global repository at /etc/boson
    def global_repo
      File.exists?('/etc/boson') ? Repo.new('/etc/boson') : nil
    end
  end
  extend Save

  class BareRunner
    module Save
      def init
        add_load_path
        super
      end

      def autoload_command(cmd, opts={verbose: Boson.verbose})
        Index.read
        (lib = Index.find_library(cmd)) && Manager.load(lib, opts)
        lib
      end

      def define_autoloader
        class << ::Boson.main_object
          def method_missing(method, *args, &block)
            if BareRunner.autoload_command(method.to_s)
              send(method, *args, &block) if respond_to?(method)
            else
              super
            end
          end
        end
      end

      def default_libraries
        Boson.repos.map {|e| e.config[:defaults] || [] }.flatten + super
      end

      # Libraries detected in repositories
      def detected_libraries
        Boson.repos.map {|e| e.detected_libraries }.flatten.uniq
      end

      # Libraries specified in config files and detected_libraries
      def all_libraries
        Boson.repos.map {|e| e.all_libraries }.flatten.uniq
      end

      def add_load_path
        Boson.repos.each {|repo|
          if repo.config[:add_load_path] || File.exists?(File.join(repo.dir, 'lib'))
            $: <<  File.join(repo.dir, 'lib') unless $:.include? File.expand_path(File.join(repo.dir, 'lib'))
          end
        }
      end
    end
    extend Save
  end

  # * All libraries can be configured by passing a hash of {library attributes}[link:classes/Boson/Library.html#M000077] under
  #   {the :libraries key}[link:classes/Boson/Repo.html#M000070] to the main config file ~/.boson/config/boson.yml.
  #   For most libraries this may be the only way to configure a library's commands.
  #   An example of a GemLibrary config:
  #    :libraries:
  #      httparty:
  #       :class_commands:
  #         delete: HTTParty.delete
  #       :commands:
  #         delete:
  #           :alias: d
  #           :desc: Http delete a given url
  #
  # When installing a third-party library, use the config file as a way to override default library and command attributes
  # without modifying the library.
  class Library
    module Save
      attr_accessor :repo_dir

      def before_initialize
        @repo_dir = set_repo.dir
      end

      def config
        set_repo.config
      end

      def set_repo
        Boson.repo
      end

      def marshal_dump
        [@name, @commands, @gems, @module.to_s, @repo_dir, @indexed_namespace]
      end

      def marshal_load(ary)
        @name, @commands, @gems, @module, @repo_dir, @indexed_namespace = ary
      end
    end
    include Save
  end

  class Command
    module Save
      def marshal_dump
        if @args && @args.any? {|e| e[1].is_a?(Module) }
          @args.map! {|e| e.size == 2 ? [e[0], e[1].inspect] : e }
          @file_parsed_args = true
        end
        [@name, @alias, @lib, @desc, @options, @render_options, @args, @default_option]
      end

      def marshal_load(ary)
        @name, @alias, @lib, @desc, @options, @render_options, @args, @default_option = ary
      end
    end
    include Save
  end

  if defined? BinRunner
  # Any changes to your commands are immediately available from
  # the commandline except for changes to the main config file.  For those
  # changes to take effect you need to explicitly load and index the libraries
  # with --index.  See RepoIndex to understand how Boson can immediately detect
  # the latest commands.
  class BinRunner
    module Save
      def autoload_command(cmd)
        if !Boson.can_invoke?(cmd, false)
          update_index
          super(cmd, load_options)
        end
      end

      def update_index
        Index.update(verbose: verbose)
      end

      def execute_command(cmd, args)
        @command = cmd # for external errors
        autoload_command cmd
        super
      end

      def command_not_found?(cmd)
        super && (!(Index.read && Index.find_command(cmd[/\w+/])) || cmd.include?(NAMESPACE))
      end

      def command_name(cmd)
        cmd.split(Boson::NAMESPACE)[-1]
      end

      def eval_execute_option(str)
        define_autoloader
        super
      end

      def default_libraries
        super + Boson.repos.map {|e| e.config[:bin_defaults] || [] }.flatten +
          Dir.glob('Bosonfile')
      end
    end
    extend Save
  end
  end
end
