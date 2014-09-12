require 'yaml'

module Conf
  HOME_PATH = File.dirname(__FILE__) + File::SEPARATOR + '..' + File::SEPARATOR
  DB_PATH = HOME_PATH + 'db' + File::SEPARATOR
  DATA_PATH = HOME_PATH + 'data' + File::SEPARATOR
  CONFIG = YAML.load_file DATA_PATH + 'config.yml'
  def conf(key)
    CONFIG[key]
  end
end