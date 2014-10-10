# -*- encoding : utf-8 -*-
require 'colorize'
require 'yaml'
require_relative 'conf'
include Conf

module Translate
  STRINGS = YAML.load_file DATA_PATH + config('language') + '.yml'
  def t(key, args = [])
    s =sprintf STRINGS[key], *args
    s.green
  end
end