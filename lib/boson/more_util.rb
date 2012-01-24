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

  end
  Util.extend MoreUtil
end
