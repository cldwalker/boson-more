# Adds dependencies to manager
module Boson
  class Manager
    module MoreManager
      def load_dependencies(lib, options={})
        lib_dependencies[lib] = Array(lib.dependencies).map do |e|
          next if loaded?(e)
          load_once(e, options.merge(:dependency=>true)) ||
            raise(LoaderError, "Can't load dependency #{e}")
        end.compact
      end

      def lib_dependencies
        @lib_dependencies ||= {}
      end

      def during_after_load
        (lib_dependencies[@library] || []).each do |e|
          create_commands(e)
          add_library(e)
          puts "Loaded library dependency #{e.name}" if @options[:verbose]
        end
      end
    end
    extend MoreManager
  end
end
