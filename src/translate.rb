require 'colorize'
require 'yaml'

require_relative 'configuration'

include Configuration

# Simple texts loader and translator
module Translate
  STRINGS = YAML.load_file DATA_PATH + config('language') + '.yml'

  def t(key, options = {})
    args = options.key?(:args) ? options[:args] : []
    color = options.key?(:color) ? options[:color] : true
    s = format STRINGS[key], *args
    if color
      s.green
    else
      s
    end
  end
end
