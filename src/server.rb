require 'socket'
require 'time'
require 'tmpdir'

require_relative 'configuration'
require_relative 'record'

include Configuration

# Server for tables with records
class Server
  DB_FILE_PATH = "#{DB_PATH}all".freeze
  LOCK_PATH = "#{Dir.tmpdir}#{File::SEPARATOR}ort.lock".freeze
  MAX_RECORDS_SENT_SIZE = config 'max_records_sent_size'
  PORT = config 'port'
  VERBOSE = config 'server_verbose'

  def lock(&block)
    File.open(LOCK_PATH, 'w') do |f|
      f.flock(File::LOCK_EX)
      block.call
      f.flock(File::LOCK_UN)
    end
  end

  def action_put(client)
    lock do
      records = Record.load DB_FILE_PATH
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
      Record.save DB_FILE_PATH, records
    end
  end

  def action_get(client)
    filter = client.readline.chomp == 'true'
    records = Record.load DB_FILE_PATH
    records = today(records) if filter
    records = records.take(MAX_RECORDS_SENT_SIZE)
    message = records.to_json
    client.write message
    client.close
  end

  def action_sync(client)
    message = client.read
    client.close
    local_records = Record.from_json message
    lock do
      records = Record.load DB_FILE_PATH
      local_records.each do |r|
        records << r unless records.include?(r)
      end
      Record.save DB_FILE_PATH, records
    end
  end

  def run
    puts "PORT: #{PORT}" if VERBOSE
    socket = nil
    begin
      Thread.abort_on_exception = true
      socket = TCPServer.open('0.0.0.0', PORT)
      loop do
        Thread.start(socket.accept) do |client|
          action = client.readline.chomp
          _af, _port, hostname, _addr = client.peeraddr(:hostname)
          print "#{hostname} : #{action}" if VERBOSE
          case action
          when 'put'
            action_put client
          when 'get'
            action_get client
          when 'sync'
            action_sync client
          else
            raise StandardError("Invalid server action: #{action}")
          end
          puts if VERBOSE
        rescue Interrupt => e
          client.close
          raise e
        end
      end
    rescue Interrupt
      socket&.close
    end
  end

  def today(records)
    records.select { |r| r.time.to_date == Date.today }
  end
end

Server.new.run
