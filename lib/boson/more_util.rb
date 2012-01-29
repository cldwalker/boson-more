module Boson
  module MoreUtil
    # Behaves just like the unix which command, returning the full path to an executable based on ENV['PATH'].
    def which(command)
      ENV['PATH'].split(File::PATH_SEPARATOR).map {|e| File.join(e, command) }.find {|e| File.exists?(e) }
    end

    # Deep copies any object if it can be marshaled. Useful for deep hashes.
    def deep_copy(obj)
      Marshal::load(Marshal::dump(obj))
    end

    # Safely calls require, returning false if LoadError occurs.
    def safe_require(lib)
      begin
        require lib
        true
      rescue LoadError
        false
      end
    end

    # Returns name of top level class that conflicts if it exists. For example, for base module Boson::Commands,
    # Boson::Commands::Hirb conflicts with Hirb if Hirb exists.
    def top_level_class_conflict(base_module, conflicting_module)
      (conflicting_module =~ /^#{base_module}.*::([^:]+)/) && Object.const_defined?($1) && $1
    end
  end
  Util.extend MoreUtil
end
