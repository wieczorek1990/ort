require 'io/console'
require 'readline'
require 'socket'
require_relative 'conf'
require_relative 'console'
require_relative 'generator'
require_relative 'record'
require_relative 'string'
require_relative 'translate'
include Conf
include Console
include Translate

class Game
  def end_game(name, good, bad)
    record = Record.new(name, Time.now, good, bad)
    @records << record
    @records.sort!
    Record::save @db_file_path, @records
    position_online = nil
    position_online_today = nil
    begin
      message = record.to_json
      socket = TCPSocket.open(@server_ip, @port)
      socket.puts 'put'
      socket.puts message
      position_online = socket.gets.chomp
      position_online_today = socket.gets.chomp
      socket.close
    rescue => e
      no_connection e
    end
    clear
    unless position_online_today.nil?
      puts t('position_online_today', position_online_today)
    end
    unless position_online.nil?
      puts t('position_online', position_online)
    end
    position_local = @records.index(record) + 1
    puts t('position_local', position_local)
    puts t('result', [good, bad])
    press_any_key_to_continue
  end
  def game
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
      seconds_left = @round_seconds - (Time.now - start)
      if seconds_left <= 0
        break
      end
      forms = []
      word = ''
      loop do
        word = Generator.get_word
        forms = Generator.get_forms(word)
        if forms.size >= @min_form_size
          forms = forms.take(@max_form_size)
          if forms.size > @trunc_form_size
            forms = forms.take(@trunc_form_size)
          end
          unless forms.include?(word)
            forms[rand(forms.length)] = word
          end
          break
        end
      end
      answer = selector(forms, { before: t('status_and_choose',
                                           [good - bad, good, bad, Time.at(seconds_left).utc.strftime('%M:%S')]) })
      if forms[answer] == word
        puts t('correct')
        good += 1
      else
        puts t('uncorrect') + word.bold
        bad += 1
      end
      press_any_key_to_continue
    end
    end_game name, good, bad
  end
  def initialize(test)
    @db_file_path = DB_PATH + Socket.gethostname
    @max_form_size = config 'max_form_size'
    @min_form_size = config 'min_form_size'
    @trunc_form_size = config 'trunc_form_size'
    @port = config 'port'
    @round_seconds = config "#{'test_' if test}round_seconds"
    @server_ip = config "#{'test_' if test}server_ip"
    @records = Record::load @db_file_path
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
  def results(records)
    clear
    unless records.empty?
      rows, cols = STDIN.winsize
      rows = rows - 3
      nickname_length = cols - 63
      format = "  %2s  |  %#{nickname_length}s  |  %16s  |  %6s  |  %5s  |  %5s  \n"
      printf format, '##', t('nickname'), t('when'), t('points'), t('good'), t('bad')
      puts '-' * cols
      many = rows > records.size ? records.size : rows
      many.times do |i|
        record = records[i]
        printf format, i + 1, record.name[0...nickname_length], record.time.strftime("%Y-%m-%d %H:%M"),
               record.points, record.good, record.bad
      end
    else
      puts t('nobody_played')
    end
    press_any_key_to_continue
  end
  def results_online(today = false)
    begin
      socket = TCPSocket.open(@server_ip, @port)
      socket.puts 'get'
      unless today
        socket.puts 'false'
      else
        socket.puts 'true'
      end
      message = socket.read
      socket.close
      records = Record.from_json message
      results records
    rescue => e
      no_connection e
    end
  end
  def sync
    begin
      message = @records.to_json
      socket = TCPSocket.open(@server_ip, @port)
      socket.puts 'sync'
      socket.write message
      socket.close
      clear
      puts t('sync_done')
      press_any_key_to_continue
    rescue => e
      no_connection e
    end
  end
  def run
    choice = nil
    loop do
      begin
        cursor 'off'
        choice = selector([t('play'), t('results_online_today'), t('results_online'), t('results_local'), t('sync'), t('exit')],
                          { before: t('welcome'), choice: choice })
        case choice
          when 0
            game
          when 1
            results_online true
          when 2
            results_online
          when 3
            results @records
          when 4
            sync
          else
            exit
        end
      rescue Interrupt, SystemExit
        clean_exit
      end
    end
  end
end