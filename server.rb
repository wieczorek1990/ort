require 'socket'
require 'yaml'
require_relative 'record'

DIR = File.dirname(__FILE__) + File::SEPARATOR
DB_PATH = DIR + 'db' + File::SEPARATOR + 'all'
CONFIG_PATH = DIR + 'config.yml'
CONFIG = YAML.load_file CONFIG_PATH
PORT = CONFIG['port']
MAX_RECORDS_SENT_SIZE = CONFIG['max_records_sent_size']

begin
  socket = TCPServer.open(PORT)
  loop {
    Thread.start(socket.accept) do |client|
      begin
        records = Record::load DB_PATH
        action = client.readline.chomp
        case action
          when 'put'
            message = client.gets.chomp
            record = Record::from_json message
            records << record
            Record::sort records
            position = records.index(record) + 1
            client.puts position
            client.close
            Record::save DB_PATH, records
          when 'get'
            records = records.take(MAX_RECORDS_SENT_SIZE)
            message = Marshal.dump(records)
            client.write message
            client.close
        end
      rescue Interrupt => e
        client.close
        raise e
      end
    end
  }
rescue Interrupt
  socket.close
end