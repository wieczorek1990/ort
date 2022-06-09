require 'yaml'

# Configuration reader and getter
module Configuration
  HOME_PATH = File.expand_path('..', File.dirname(__FILE__)) + File::SEPARATOR
  DB_PATH = "#{Dir.home}#{File::SEPARATOR}.ort-db#{File::SEPARATOR}".freeze
  DATA_PATH = "#{HOME_PATH}data#{File::SEPARATOR}".freeze
  CONFIG = YAML.load_file "#{DATA_PATH}config.yml"

  def config(key)
    CONFIG[key]
  end
end
