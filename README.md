## Description

boson-more is a collection of useful boson plugins. These plugins add features
such as allowing boson to be used from irb, optional automated views generated
by hirb and allowing libraries to be written as plain ruby. For my libraries
that use this, see [irbfiles](http://github.com/cldwalker/irbfiles).

## Usage

To use all of the plugins, add this to ~/.bosonrc:

    require 'boson/more'

To only use certain plugins, require those plugins in ~/.bosonrc.

When using all plugins, you can use boson in irb/ripl by dropping this in ~/.irbrc:

    require 'boson/console'
    Boson.start


## List of Plugins

* boson/alias - Adds aliasing to commands. Requires alias gem.
* boson/console - Allows for boson to be used in a ruby console.
* boson/libraries - Adds several libraries. Necessary for using old boson.
* boson/more\_commands - Adds set of default commands
* boson/more\_inspector - Adds commenting-based command configuration.
* boson/more\_manager - Adds ability for libraries to have dependencies.
* boson/more\_method\_inspector - Adds ability to scrape argument names and
  default values from commands.
* boson/more\_scientist - Adds a few global options to option commands.
* boson/runner\_options - Adds additional options to the boson executable.
* boson/science - Adds pipes and several global options to option commands.
  Requires hirb.
* boson/namespacer - Adds namespaces to commands.
* boson/save - Allows libraries and commands to be saved and loaded quickly.
  Necessary for using old boson.
* boson/viewable - Adds rendering to commands. Requires hirb.

## Features

When using all these plugins, they have the following features:

* Simple organization: Commands are just methods on an object (default is main)
  and command libraries are just modules.
* Commands are accessible from the commandline (Boson::BinRunner) or irb
  (Boson::ConsoleRunner).
* Libraries
  * can be written in plain ruby which allows for easy testing and use
    independent of boson (Boson::FileLibrary).
  * can exist locally as a Bosonfile (Boson::LocalFileLibrary) and under
    lib/boson/commands or .boson/commands.
  * can be made from gems (Boson::GemLibrary) or any require-able file
    (Boson::RequireLibrary).
  * are encouraged to be shared. Libraries can be installed with a given url.
    Users can customize any aspect of a third-party library without modifying it
    (Boson::Library).
* Commands
  * can have any number of local and global options (Boson::OptionCommand).
    Options are defined with Boson::OptionParser.
  * can have any view associated to it (via Hirb) without adding view code to
    the command's method.  These views can be toggled on and manipulated via
    global render options (Boson::View and Boson::OptionCommand).
  * can pipe their return value into custom pipe options (Boson::Pipe).
  * has default pipe options to search and sort an array of any objects
    (Boson::Pipes).
* Option parser (Boson::OptionParser)
  * provides option types that map to objects i.e. :array type creates Array
    objects.
  * come with 5 default option types: boolean, array, string, hash and numeric.
  * can have have custom option types defined by users (Boson::Options).
* Comes with default commands to load, search, list and install commands and
  libraries (Boson::Commands::Core).
* Namespaces are optional and when used are methods which allow for
  method\_missing magic.


## Bugs/Issues

Please report them [on github](http://github.com/cldwalker/boson-more/issues).

## Contributing

[See here](http://tagaholic.me/contributing.html)

## Links

* http://tagaholic.me/2009/10/14/boson-command-your-ruby-universe.html
* http://tagaholic.me/2009/10/15/boson-and-hirb-interactions.html
* http://tagaholic.me/2009/10/19/how-boson-enhances-your-irb-experience.html
## TODO

* Actually have working tests
* Clean up plugins and move their files into separates directories
* Clean up plugins that unintentionally depend on each other
* Clean up docs which are currently strewn across plugins
