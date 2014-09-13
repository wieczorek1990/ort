require 'yaml'

module Conf
  HOME_PATH = File.expand_path('..', File.dirname(__FILE__)) + File::SEPARATOR
  DB_PATH = HOME_PATH + 'db' + File::SEPARATOR
  DATA_PATH = HOME_PATH + 'data' + File::SEPARATOR
  CONFIG = YAML.load_file DATA_PATH + 'config.yml'
  def config(key)
    CONFIG[key]
  end
end