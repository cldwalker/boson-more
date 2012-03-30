# depends on browser command
require 'boson/save'

module Boson
  class Command
    module UrlLibraries
      def library_attributes(library)
        !library.name.include?('url/') ? super :
          super.update(:render_options=>{:pipes=>{:default=>['browser']}, :render=>true})
      end
    end
    extend UrlLibraries
  end
end
