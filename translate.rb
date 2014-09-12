require 'yaml'
require_relative 'conf'
include Conf

module Translate
  STRINGS = YAML.load_file File.dirname(__FILE__) + File::SEPARATOR  + conf('language') + '.yml'
  def t(key, args = [])
    sprintf STRINGS[key], *args
  end
end