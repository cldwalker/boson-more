module Boson::Commands::ViewCore
  def config
    commands = {
      'render'=>{:desc=>"Render any object using Hirb"},
      'menu'=>{:desc=>"Provide a menu to multi-select elements from a given array"}
    }
    {:namespace=>false, :library_file=>File.expand_path(__FILE__), :commands=>commands}
  end
  def render(object, options={})
    Boson::View.render(object, options)
  end

  def menu(arr, options={}, &block)
    Hirb::Console.format_output(arr, options.merge(:class=>"Hirb::Menu"), &block)
  end
end
