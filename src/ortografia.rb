# encoding: UTF-8
require 'io/console'
require 'readline'
require 'socket'
require_relative 'conf'
require_relative 'end_game'
require_relative 'ort'
require_relative 'record'
require_relative 'string'
require_relative 'translate'
include Conf
include Translate

DB_FILE_PATH = DB_PATH + Socket.gethostname
RECORDS = Record::load DB_FILE_PATH
TEST = ARGV[0] == 'test' ? true : false
MIN_FORM_SIZE = conf 'min_form_size'
PORT = conf 'port'
ROUND_SECONDS = conf "#{'test_' if TEST}round_seconds"
SERVER_IP = conf "#{'test_' if TEST}server_ip"

def clear
  system 'clear'
end
def cursor(setting)
  system "setterm -cursor #{setting}"
end
def no_connection(e)
  clear
  puts t('no_connection')
  puts '"' + e.message + '"'
  press_any_key_to_continue
end
def press_any_key_to_continue
  print t('press_any_key_to_continue')
  cursor 'on'
  read_char
  cursor 'off'
end
def read_char
  STDIN.echo = false
  STDIN.raw!
  input = STDIN.getc.chr
  if input == "\e" then
    input << STDIN.read_nonblock(3) rescue nil
    input << STDIN.read_nonblock(2) rescue nil
  end
ensure
  STDIN.echo = true
  STDIN.cooked!
  return input
end
def results(records)
  clear
  unless records.empty?
    rows, cols = STDIN.winsize
    rows = rows - 3
    nickname_length = cols - 52
    format = "  %2s  |  %#{nickname_length}s  |  %16s  |  %5s  |  %5s  \n"
    printf format, '##', t('nickname'), t('when'), t('good'), t('bad')
    puts '-' * cols
    many = rows > records.size ? records.size : rows
    many.times do |i|
      record = records[i]
      printf format, i + 1, record.name[0...nickname_length], record.time.strftime("%Y-%m-%d %H:%M"),
             record.good, record.bad
    end
  else
    puts t('nobody_played')
  end
  press_any_key_to_continue
end
def selector(options, extra = {})
  before = extra[:before].nil? ? '' : extra[:before]
  after = extra[:after].nil? ? '' : extra[:after]
  choice = extra[:choice].nil? ? 0 : extra[:choice]
  loop do
    clear
    print before
    options.each_with_index do |line, i|
      if i != choice
        puts line
      else
        puts line.highlight
      end
    end
    print after
    c = read_char
    case c
      when "\r", ' '
        return choice
      when "\e"
        exit
      when "\e[A"
        choice = choice - 1 < 0 ? options.size - 1 : choice - 1
      when "\e[B"
        choice = choice + 1 > options.size - 1 ? 0 : choice + 1
    end
  end
end

choice = nil
loop do
  begin
    cursor 'off'
    choice = selector([t('play'), t('results_local'), t('results_online'), t('sync'), t('exit')],
                      { before: t('welcome'), choice: choice })
    case choice
      when 0
        good = 0
        bad = 0
        name = ''
        loop do
          clear
          cursor 'on'
          print t('nickname_prompt')
          name = Readline.readline
          unless name.empty?
            cursor 'off'
            break
          end
        end
        start = Time.now
        loop do
          seconds_left = ROUND_SECONDS - (Time.now - start)
          if seconds_left <= 0
            raise EndGame
          end
          forms = []
          word = ''
          loop do
            word = Ort.get_word
            forms = Ort.get_forms(word)
            if forms.size >= MIN_FORM_SIZE
              break
            end
          end
          answer = selector(forms, { before: t('status_and_choose',
                                               [good, bad, Time.at(seconds_left).utc.strftime('%M:%S')]) })
          if forms[answer] == word
            puts t('correct')
            good += 1
          else
            puts t('uncorrect') + word.bold
            bad += 1
          end
          press_any_key_to_continue
        end
      when 1
        results RECORDS
      when 2
        begin
          socket = TCPSocket.open(SERVER_IP, PORT)
          socket.puts 'get'
          message = socket.read
          socket.close
          records = Record.from_json message
          results records
        rescue => e
          no_connection e
        end
      when 3
        begin
          message = RECORDS.to_json
          socket = TCPSocket.open(SERVER_IP, PORT)
          socket.puts 'sync'
          socket.write message
          socket.close
          clear
          puts t('sync_done')
          press_any_key_to_continue
        rescue => e
          no_connection e
        end
      else
        exit
    end
  rescue EndGame
    record = Record.new(name, Time.now, good, bad)
    RECORDS << record
    RECORDS.sort!
    Record::save DB_FILE_PATH, RECORDS
    position_online = nil
    begin
      message = record.to_json
      socket = TCPSocket.open(SERVER_IP, PORT)
      socket.puts 'put'
      socket.puts message
      position_online = socket.gets.chomp
      socket.close
    rescue => e
      no_connection e
    end
    clear
    unless position_online.nil?
      puts t('position_online', position_online)
    end
    position_local = RECORDS.index(record) + 1
    puts t('position_local', position_local)
    puts t('result', [good, bad])
    press_any_key_to_continue
  rescue SystemExit
    cursor 'on'
    clear
    exit
  end
end