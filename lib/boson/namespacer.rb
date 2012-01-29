require 'boson/namespace'

module Boson
  NAMESPACE = '.' # Delimits namespace from command
  module Commands
    # Used for defining namespaces.
    module Namespace; end
  end
  Universe.send :include, Commands::Namespace

  module Namespacer
    # Invoke command string even with namespaces
    def full_invoke(cmd, args) #:nodoc:
      command, subcommand = cmd.include?(NAMESPACE) ? cmd.split(NAMESPACE, 2) : [cmd, nil]
      dispatcher = subcommand ? Boson.invoke(command) : Boson.main_object
      dispatcher.send(subcommand || command, *args)
    end
  end
  extend Namespacer

  class Command
    INIT_ATTRIBUTES << :namespace
    module NamespacerClass
      def library_attributes(library)
        super.update(namespace: library.namespace)
      end

      def find(command, commands=Boson.commands)
        if command.to_s.include?(NAMESPACE)
          command, subcommand = command.to_s.split(NAMESPACE, 2)
          commands.find {|current_command|
            [current_command.name, current_command.alias].include?(subcommand) &&
            current_command.library && (current_command.library.namespace == command)
          }
        else
          commands.find {|e| [e.name, e.alias].include?(command) && !e.namespace}
        end
      end
    end
    extend NamespacerClass

    module Namespacer
      attr_accessor :namespace

      # Full name is only different than name if a command has a namespace.
      # The full name should be what you would type to execute the command.
      def full_name
        @namespace ? "#{@namespace}.#{@name}" : @name
      end
    end
    include Namespacer
  end

  class Library
    # [*:namespace*] Boolean or string which namespaces a library. When true, the library is automatically namespaced
    #                to the library's name. When a string, the library is namespaced to the string. Default is nil.
    module Namespacer
      # Optional namespace name for a library. When enabled defaults to a library's name.
      attr_writer :namespace

      # The object a library uses for executing its commands.
      def namespace_object
        @namespace_object ||= namespace ? Boson.invoke(namespace) : Boson.main_object
      end

      def namespace(orig=@namespace)
        @namespace = [String,FalseClass].include?(orig.class) ? orig : begin
          if (@namespace == true || (Boson.config[:auto_namespace] && !@index))
            @namespace = clean_name
          else
            @namespace = false
          end
        end
      end
    end
    include Namespacer

    module NamespaceLoader
      attr_reader :indexed_namespace, :object_namespace

      def handle_method_conflict_error(err)
        if Boson.config[:error_method_conflicts] || namespace
          raise MethodConflictError, err.message
        else
          @namespace = clean_name
          @method_conflict = true
          $stderr.puts "#{err.message}. Attempting load into the namespace #{@namespace}..."
          initialize_library_module
        end
      end

      def after_initialize_library_module
        @namespace = clean_name if @object_namespace
        namespace ? Namespace.create(namespace, self) : include_in_universe
      end

      def method_conflicts
        namespace ?
          (Boson.can_invoke?(namespace) ?  [namespace] : []) :
          super
      end

      def clean_library_commands
        @commands.delete(namespace) if namespace
        @commands += Boson.invoke(namespace).boson_commands if namespace && !@pre_defined_commands
        super
      end

      def set_library_commands
        @namespace = false if !(@module || @class_commands)
        super
        @indexed_namespace = (@namespace == false) ? nil : @namespace if @index
      end
    end
    include NamespaceLoader
  end
end
