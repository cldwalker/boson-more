require 'boson/commands/core'
require 'boson/commands/web_core'
require 'boson/commands/view_core'
require 'boson/runner'

Boson::Runner::DEFAULT_LIBRARIES << Boson::Commands::Core
Boson::Runner::DEFAULT_LIBRARIES << Boson::Commands::WebCore
# dir = File.dirname(File.readlink(__FILE__))
dir = File.expand_path "~/code/gems/boson-all/lib/boson"
Boson.repos << Boson::Repo.new(dir)
