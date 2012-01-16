require 'boson/comment_inspector'

module Boson
  # When deciding whether to use commented or normal Module methods, remember that commented Module methods allow
  # independence from Boson (useful for testing).
  # See CommentInspector for more about commented method attributes.
  module Inspector
    module MoreInspector
      def add_method_data_to_library(library)
        super
        add_comment_scraped_data
      end

      def add_comment_scraped_data
        (@store[:method_locations] || []).select {|k,(f,l)| f == @library_file }.each do |cmd, (file, lineno)|
          scraped = CommentInspector.scrape(FileLibrary.read_library_file(file), lineno, MethodInspector.current_module)
          @commands_hash[cmd] ||= {}
          MethodInspector::METHODS.each do |e|
            add_valid_data_to_config(e, scraped[e], cmd)
          end
        end
      end
    end
    extend MoreInspector
  end

  # This module also saves method locations so CommentInspector
  # can scrape their commented method attributes.
  module MethodInspector
    module MoreInspector
      def inspector_in_file?(meth, inspector_method)
        return false if !super
        if File.exists?(file_line[0]) && (options = CommentInspector.scrape(
          FileLibrary.read_library_file(file_line[0]), file_line[1], @current_module, inspector_method) )
          (store[inspector_method] ||= {})[meth] = options
        end
      end
      extend MoreInspector
    end
  end
end
