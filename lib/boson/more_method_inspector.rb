module Boson
  class MethodInspector
    # Returns argument arrays
    def self.scrape_arguments(file_string, meth)
      tabspace = "[ \t]"
      if match = /^#{tabspace}*def#{tabspace}+(?:\w+\.)?#{Regexp.quote(meth)}#{tabspace}*($|(?:\(|\s+)([^\n\)]+)\s*\)?\s*$)/.match(file_string)
        (match.to_a[2] || '').strip.split(/\s*,\s*/).map {|e| e.split(/\s*=\s*/)}
      end
    end

    # investigate why this can't be included
    def inspector_in_file?(meth, inspector_method)
      !(file_line = store[:method_locations] && store[:method_locations][meth]) ?
        false : true
    end

    module MoreMethodInspector
      def during_new_method_added(mod, meth)
        if store[:temp].size < ALL_METHODS.size
          store[:method_locations] ||= {}
          if (result = find_method_locations(mod, meth))
            store[:method_locations][meth.to_s] = result
          end
        end
      end

      def set_arguments(mod, meth)
        store[:args] ||= {}
        file = find_method_locations(mod, meth)[0]

        if File.exists?(file)
          body = File.read(file)
          store[:args][meth.to_s] = self.class.scrape_arguments body, meth
        end
      end

      def has_inspector_method?(meth, inspector)
        (store[inspector] && store[inspector].key?(meth.to_s)) ||
          inspector_in_file?(meth.to_s, inspector)
      end

      # Returns an array of the file and line number at which a method starts
      # using a method
      def find_method_locations(mod, meth)
        mod.instance_method(meth).source_location
      end
    end
    include MoreMethodInspector
  end

  class Command
    module MoreMethodInspector
      # One-line usage of args with default values
      def basic_usage
        return '' if options.nil? && args.nil?
        args ? usage_args.map {|e|
          (e.size < 2) ? "[#{e[0]}]" :
            "[#{e[0]}=#{@file_parsed_args ? e[1] : e[1].inspect}]"
        }.join(' ') : '[*unknown]'
      end
    end
    include MoreMethodInspector
  end
end
