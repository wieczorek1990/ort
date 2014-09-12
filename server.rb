require 'socket'
require 'tmpdir'
require_relative 'record'
require_relative 'conf'
include Conf

DB_PATH = File.dirname(__FILE__) + File::SEPARATOR + 'db' + File::SEPARATOR + 'all'
LOCK_PATH = Dir.tmpdir() + File::SEPARATOR + 'ort.lock'
PORT = conf 'port'
MAX_RECORDS_SENT_SIZE = conf 'max_records_sent_size'

def lock(&block)
  File.open(LOCK_PATH, 'w') do |f|
    f.flock(File::LOCK_EX)
    block.call
    f.flock(File::LOCK_UN)
  end
end

begin
  Thread.abort_on_exception = true
  socket = TCPServer.open(PORT)
  loop {
    Thread.start(socket.accept) do |client|
      begin
        action = client.readline.chomp
        af, port, hostname, addr = client.peeraddr(:hostname)
        print hostname + ' : ' + action
        case action
          when 'put'
            lock do
              records = Record::load DB_PATH
              message = client.gets.chomp
              record = Record.from_json message
              records << record
              records.sort!
              position = records.index(record) + 1
              client.puts position
              client.close
              Record::save DB_PATH, records
            end
          when 'get'
            records = Record::load DB_PATH
            records = records.take(MAX_RECORDS_SENT_SIZE)
            message = records.to_json
            client.write message
            client.close
          when 'sync'
            message = client.read
            client.close
            local_records = Record::from_json message
            lock do
              records = Record::load DB_PATH
              local_records.each do |r|
                unless records.include?(r)
                  records << r
                end
              end
              Record::save DB_PATH, records
            end
        end
      puts
      rescue Interrupt => e
        client.close
        raise e
      end
    end
  }
rescue Interrupt
  socket.close
end