require 'yaml'
require_relative 'conf'
include Conf

module Translate
  STRINGS = YAML.load_file DATA_PATH + conf('language') + '.yml'
  def t(key, args = [])
    sprintf STRINGS[key], *args
  end
end