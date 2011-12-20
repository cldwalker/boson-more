require 'boson/view'

module Boson
  if defined? BinRunner
    class BinRunner
      module Viewable
        def print_usage_header
          super
          puts "GLOBAL OPTIONS"
          View.enable
        end
      end
      class << self; include Viewable; end
    end
  end

  class Runner
    module Viewable
      def init
        View.enable
        super
      end
    end
    class << self; include Viewable; end
  end

  class OptionParser
    module Viewable
      def get_fields_and_options(fields, options)
        (fields << :default).uniq! if options.delete(:local) || options[:fields] == '*'
        fields, opts = super(fields, options)
        fields.delete(:default) if fields.include?(:default) && opts.all? {|e| e[:default].nil? }
        [fields, opts]
      end

      def default_render_options #:nodoc:
        {:header_filter=>:capitalize, :description=>false, :filter_any=>true,
          :filter_classes=>{Array=>[:join, ',']}, :hide_empty=>true}
      end

      def render_table(fields, arr, options)
        options = default_render_options.merge(:fields=>fields).merge(options)
        View.render arr, options
      end
    end
    include Viewable
  end
end
