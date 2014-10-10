# -*- encoding : utf-8 -*-
require 'socket'
require 'time'
require 'tmpdir'
require_relative 'conf'
require_relative 'record'
include Conf

class Server
  DB_FILE_PATH = DB_PATH + 'all'
  LOCK_PATH = Dir.tmpdir() + File::SEPARATOR + 'ort.lock'
  MAX_RECORDS_SENT_SIZE = config 'max_records_sent_size'
  PORT = config 'port'
  def lock(&block)
    File.open(LOCK_PATH, 'w') do |f|
      f.flock(File::LOCK_EX)
      block.call
      f.flock(File::LOCK_UN)
    end
  end
  def run
    puts "PORT: #{PORT}"
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
                  records = Record::load DB_FILE_PATH
                  message = client.gets.chomp
                  json = Record.from_json message
                  record = json[0]
                  records << record
                  records.sort!
                  position = records.index(record) + 1
                  position_today = today(records).index(record) + 1
                  client.puts position
                  client.puts position_today
                  client.close
                  Record::save DB_FILE_PATH, records
                end
              when 'get'
                filter = client.readline.chomp == 'true' ? true : false
                records = Record::load DB_FILE_PATH
                if filter
                  records = today(records)
                end
                records = records.take(MAX_RECORDS_SENT_SIZE)
                message = records.to_json
                client.write message
                client.close
              when 'sync'
                message = client.read
                client.close
                local_records = Record::from_json message
                lock do
                  records = Record::load DB_FILE_PATH
                  local_records.each do |r|
                    unless records.include?(r)
                      records << r
                    end
                  end
                  Record::save DB_FILE_PATH, records
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
  end
  def today(records)
    records.select { |r| r.time.to_date == Date.today }
  end
end

Server.new.run