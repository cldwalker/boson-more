require 'boson/commands/core'
require 'boson/commands/web_core'
require 'boson/commands/view_core'
require 'boson/runner'

Boson::BareRunner::DEFAULT_LIBRARIES << Boson::Commands::Core
Boson::BareRunner::DEFAULT_LIBRARIES << Boson::Commands::WebCore
Boson::BareRunner::DEFAULT_LIBRARIES << Boson::Commands::ViewCore
# dir = File.dirname(File.readlink(__FILE__))
dir = File.expand_path "~/code/gems/boson-all/lib/boson"
Boson.repos << Boson::Repo.new(dir)
