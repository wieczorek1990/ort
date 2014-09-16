require 'io/console'
require 'readline'
require 'socket'
require_relative 'conf'
require_relative 'console'
require_relative 'enumerable'
require_relative 'generator'
require_relative 'record'
require_relative 'string'
require_relative 'translate'
include Conf
include Console
include Translate

class Game
  def cheated(play_time, answer_times)
    minimum_seconds_per_round = config 'minimum_seconds_per_round'
    minimum_answer_seconds = config 'minimum_answer_seconds'
    if play_time < minimum_seconds_per_round
      return true
    end
    mean = answer_times.mean
    deviation = 3 * answer_times.standard_deviation
    fast_answers = answer_times.select { |a| a > mean - deviation and a < mean + deviation }
    if fast_answers.mean < minimum_answer_seconds
      return true
    end
    return false
  end
  def end_game(name, good, bad, start, answer_times)
    stop = Time.now
    if cheated(stop - start, answer_times)
      clear
      message = t('cheating') + ' '
      rows, cols = STDIN.winsize
      max = rows * cols
      (max / message.length).round.times do
        print message
      end
      loop do
        if STDIN.getch == "\u001C"
            exit
        end
      end
    end
    record = Record.new(name, stop, good, bad)
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
    puts t('game_time', format_seconds(stop - start))
    unless position_online_today.nil?
      puts t('position_online_today', position_online_today)
    end
    unless position_online.nil?
      puts t('position_online', position_online)
    end
    position_local = @records.index(record) + 1
    puts t('position_local', position_local)
    puts t('result', [good - bad, good, bad])
    press_any_key_to_continue
  end
  def format_seconds(seconds)
    Time.at(seconds).utc.strftime('%M:%S')
  end
  def game
    good = 0
    bad = 0
    name = ''
    answer_times = []
    loop do
      clear
      cursor 'on'
      name = Readline.readline t('nickname_prompt')
      unless name.empty?
        cursor 'off'
        break
      end
    end
    start = Time.now
    @questions_count.times do |question_no|
      seconds_left = @round_seconds - (Time.now - start)
      if seconds_left <= 0
        break
      end
      forms = []
      word = ''
      loop do
        word = Generator.get_word
        forms = Generator.get_forms(word)
        forms = forms.take(@max_form_size)
        if forms.size >= @min_form_size
          unless forms.include?(word)
            forms[rand(forms.length)] = word
          end
          break
        end
      end
      answer_start = Time.now
      answer = selector(forms, { before: t('status_and_choose',
                                           [format_seconds(seconds_left), question_no, good - bad, good, bad]),
                                 choice: (forms.size-1)/2 })
      answer_end = Time.now
      answer_times << answer_end - answer_start
      if forms[answer] == word
        puts t('correct')
        good += 1
      else
        puts t('uncorrect') + word.bold
        bad += 1
      end
      press_any_key_to_continue
    end
    end_game name, good, bad, start, answer_times
  end
  def initialize(test)
    @db_file_path = DB_PATH + Socket.gethostname
    @max_form_size = config 'max_form_size'
    @min_form_size = config 'min_form_size'
    @trunc_form_size = config 'trunc_form_size'
    @port = config 'port'
    @questions_count = config 'questions_count'
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