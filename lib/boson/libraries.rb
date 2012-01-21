require 'boson/save'
require 'boson/namespace'
# order of library subclasses matters
%w{module file gem require local_file}.each {|e| require "boson/libraries/#{e}_library" }

module Boson
  class Library
    module Libraries
      def local?
        is_a?(LocalFileLibrary) ||
          (Boson.local_repo && Boson.local_repo.dir == repo_dir)
      end
    end
    include Libraries
  end

  class Manager
    module Libraries
      def before_create_commands(lib)
        super
        if lib.is_a?(FileLibrary) && lib.module
          Inspector.add_method_data_to_library(lib)
        end
      end

      def add_failed_library(library)
        FileLibrary.reset_file_cache(library.to_s)
        super
      end

      def check_for_uncreated_aliases(lib, commands)
        return if lib.is_a?(GemLibrary)
        super
      end
    end
    include Libraries
  end

  class Command
    # hack: have to override
    # Array of array args with optional defaults. Scraped with MethodInspector
    def args(lib=library)
      @args = !@args.nil? ? @args : begin
        if lib
          file_string, meth = file_string_and_method_for_args(lib)
          (file_string && meth && (@file_parsed_args = true) &&
            MethodInspector.scrape_arguments(file_string, meth))
        end || false
      end
    end

    module Libraries
      def file_string_and_method_for_args(lib)
        if !lib.is_a?(ModuleLibrary) && (klass_method = (lib.class_commands || {})[@name])
          klass, meth = klass_method.split(NAMESPACE, 2)
          if (meth_locations = MethodInspector.find_class_method_locations(klass, meth))
            file_string = File.read meth_locations[0]
          end
        elsif File.exists?(lib.library_file || '')
          file_string, meth = FileLibrary.read_library_file(lib.library_file), @name
        end
        [file_string, meth]
      end
    end
    include Libraries
  end
end
