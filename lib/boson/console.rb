require 'boson/console_runner'

module Boson
  CONFIG.update console_defaults: []

  # Additional options added to Repo:
  # [:console_defaults] Array of libraries to load at start up when used in irb. Default is to load all library files and libraries
  #                     defined in the config.
  # [:console] Console to load when using --console from commandline. Default is irb.
  module Console
    # Start Boson by loading repositories and their configured libraries.
    # See ConsoleRunner.start for its options.
    def start(options={})
      ConsoleRunner.start(options)
    end
  end
  extend Console

  # [:console] This drops Boson into irb after having loaded default commands and any explict libraries with
  #            :load option. This is a good way to start irb with only certain libraries loaded.
  module ConsoleOptions
    def early_option?(args)
      if @options[:console]
        ConsoleRunner.bin_start(@options[:console], @options[:load])
        true
      else
        super
      end
    end
  end

  if defined? BinRunner
    class BinRunner < Runner
      GLOBAL_OPTIONS.update console:
        {:type=>:boolean,
          :desc=>"Drops into irb with default and explicit libraries loaded"}
      extend ConsoleOptions
    end
  end
end
