require 'boson/commands/core'
require 'boson/commands/web_core'
require 'boson/commands/view_core'
require 'boson/runner'
require 'fileutils'

Boson::BareRunner::DEFAULT_LIBRARIES << Boson::Commands::Core
Boson::BareRunner::DEFAULT_LIBRARIES << Boson::Commands::WebCore
Boson::BareRunner::DEFAULT_LIBRARIES << Boson::Commands::ViewCore

# TODO: Use Boson.home when it exists
dir = Dir.home + '/.boson/.more_commands'
FileUtils.mkdir_p dir
Boson.repos << Boson::Repo.new(dir)
