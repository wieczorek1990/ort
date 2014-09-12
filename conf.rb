require 'yaml'

module Conf
  CONFIG = YAML.load_file File.dirname(__FILE__) + File::SEPARATOR + 'config.yml'
  def conf(key)
    CONFIG[key]
  end
end