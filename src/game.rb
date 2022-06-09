require 'colorize'
require 'readline' unless Gem.win_platform?
require 'socket'
require 'timeout'

require_relative 'configuration'
require_relative 'console'
require_relative 'enumerable'
require_relative 'exceptions'
require_relative 'generator'
require_relative 'record'
require_relative 'translate'

include Configuration
include Console
include Translate

# Main game class
class Game
  def get_socket
    Timeout.timeout(@socket_timeout_seconds) do
      TCPSocket.open(@server, @port)
    end
  rescue Errno::ENETUNREACH, Errno::ECONNREFUSED, Timeout::Error
    raise NoConnection
  end

  def cheated(play_time)
    minimum_seconds_per_round = config 'minimum_seconds_per_round'
    minimum_answer_seconds = config 'minimum_answer_seconds'
    return true if play_time < minimum_seconds_per_round
    mean = @answer_times.mean
    deviation = 3 * @answer_times.standard_deviation
    fast_answers = @answer_times.select do |a|
      a > mean - deviation && a < mean + deviation
    end
    fast_answers.mean < minimum_answer_seconds
  end

  def end_game(name, start)
    stop = Time.now
    if cheated(stop - start) && !@test
      clear
      message = "#{t('cheating')} "
      rows, cols = $stdout.winsize
      max = rows * cols
      (max / message.length).round.times do
        print message
      end
      loop do
        # ctrl+\
        clean_exit if read_keystroke == 28
      end
    end
    record = Record.new(name, stop, @good, @bad)
    @records << record
    @records.sort!
    Record.save @db_file_path, @records
    position_online = nil
    position_online_today = nil
    begin
      message = record.to_json
      socket = get_socket
      socket.puts 'put'
      socket.puts message
      position_online = socket.gets.chomp
      position_online_today = socket.gets.chomp
      socket.close
    rescue NoConnection => e
      no_connection e
    end
    clear
    puts t('game_time', args: format_seconds(stop - start))
    puts t('position_online_today', args: position_online_today) unless position_online_today.nil?
    puts t('position_online', args: position_online) unless position_online.nil?
    position_local = @records.index(record) + 1
    puts t('position_local', args: position_local)
    puts t('result', args: [@good - @bad, @good, @bad])
    press_any_key_to_continue
  end

  def format_seconds(seconds)
    Time.at(seconds).utc.strftime('%M:%S')
  end

  def get_name
    name = ''
    loop do
      clear
      cursor 'on'
      prompt = t('nickname_prompt')
      begin
        if Gem.win_platform?
          print prompt
          name = $stdin.gets.chomp
        else
          begin
            name = Readline.readline("#{prompt}\e[33m") # yellow
          ensure
            printf "\e[0m" # terminator
          end
        end
      rescue StandardError
        clean_exit
      end
      unless name.empty?
        cursor 'off'
        break
      end
    end
    name
  end

  def construct_forms(question_no, seconds_left)
    forms = []
    loop do
      word = Generator.sample_word
      forms = Generator.gen_forms(word)
      forms = forms.take(@max_form_size)
      if forms.size >= @min_form_size
        forms[rand(forms.length)] = word unless forms.include?(word)
        break
      end
    end
    answer_start = Time.now
    answer_args = [
      format_seconds(seconds_left),
      question_no,
      @good - @bad,
      @good,
      @bad
    ]
    answer = selector(forms,
                      before: t('status_and_choose', args: answer_args),
                      choice: (forms.size - 1) / 2)
    answer_end = Time.now
    @answer_times << (answer_end - answer_start)
    [forms, answer].freeze
  end

  def game
    @good = 0
    @bad = 0
    @answer_times = []
    name = get_name
    start = Time.now
    @questions_count.times do |question_no|
      seconds_left = @round_seconds - (Time.now - start)
      break if seconds_left <= 0
      @word = ''
      forms, answer = construct_forms question_no, seconds_left
      if forms[answer] == @word
        puts t('correct')
        @good += 1
      else
        puts t('uncorrect') + @word.yellow.swap
        @bad += 1
      end
      press_any_key_to_continue
    end
    end_game name, start
  end

  def initialize(test)
    @db_file_path = DB_PATH + Socket.gethostname
    @max_form_size = config 'max_form_size'
    @min_form_size = config 'min_form_size'
    @trunc_form_size = config 'trunc_form_size'
    @port = config 'port'
    @questions_count = config 'questions_count'
    @round_seconds = config "#{'test_' if test}round_seconds"
    @server = config "#{'test_' if test}server"
    @socket_timeout_seconds = config 'socket_timeout_seconds'
    @records = Record.load @db_file_path
    @test = test
  end

  def no_connection(error)
    clear
    puts t('no_connection')
    if @test
      puts error.message
      puts error.backtrace
    end
    press_any_key_to_continue
  end

  def press_any_key_to_continue
    print t('press_any_key_to_continue')
    cursor 'on'
    read_keystroke
    cursor 'off'
  end

  def results(records)
    clear
    if records.empty?
      puts t('nobody_played')
    else
      rows, cols = $stdout.winsize
      rows -= - 3
      nickname_length = cols - 63
      format_lengths = [2, nickname_length, 16, 6, 5, 5]
      format = format_lengths.map { |len| "%#{len}s" }.join('  |  ')
      format = "  #{format}  \n"
      header = sprintf format,
                       '##',
                       t('nickname', color: false),
                       t('when', color: false),
                       t('points', color: false),
                       t('good', color: false),
                       t('bad', color: false)
      printf header.green
      puts '-' * cols
      many = rows > records.size ? records.size : rows
      many.times do |i|
        record = records[i]
        row = sprintf format,
                      i + 1,
                      record.name[0...nickname_length],
                      record.time.strftime('%Y-%m-%d %H:%M'),
                      record.points,
                      record.good,
                      record.bad
        printf row.yellow
      end
    end
    press_any_key_to_continue
  end

  def results_online(today: false)
    socket = get_socket
    socket.puts 'get'
    if today
      socket.puts 'true'
    else
      socket.puts 'false'
    end
    message = socket.read
    socket.close
    records = Record.from_json message
    results records
  rescue NoConnection => e
    no_connection e
  end

  def sync
    message = @records.to_json
    socket = get_socket
    socket.puts 'sync'
    socket.write message
    socket.close
    clear
    puts t('sync_done')
    press_any_key_to_continue
  rescue NoConnection => e
    no_connection e
  end

  def run
    choice = nil
    loop do
      cursor 'off'
      choices = [
        t('play'),
        t('results_online_today'),
        t('results_online'),
        t('results_local'),
        t('sync'),
        t('exit')
      ]
      choice = selector(choices, before: t('welcome'), choice: choice)
      case choice
      when 0
        game
      when 1
        results_online today: true
      when 2
        results_online today: false
      when 3
        results @records
      when 4
        sync
      else
        clean_exit
      end
    end
  end
end
