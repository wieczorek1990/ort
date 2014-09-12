#!/usr/bin/ruby
# encoding: UTF-8
require 'io/console'
require 'readline'
require 'socket'
require 'thread'
require 'yaml'
require_relative 'ort.rb'

class EndGame < Exception
end
class String
  def bold
    "\033[1m#{self}\033[22m"
  end
  def highlight
    "\033[7m#{self}\033[27m"
  end
end
class Record
  attr_reader :name, :time, :good, :bad
  def initialize(name, time, good, bad)
    @name = name
    @time = time
    @good = good
    @bad = bad
  end
  def marshal_dump
    [@name, @time, @good, @bad]
  end
  def marshal_load array
    @name, @time, @good, @bad = array
  end
end

hostname = Socket.gethostname
DIR = File.dirname(__FILE__) + File::SEPARATOR
CONFIG_PATH = DIR + 'config.yml'
config = YAML.load_file CONFIG_PATH
ROUND_SECONDS = config['round_seconds']
MIN_FORM_SIZE = config['min_form_size']
SERVER_IP = config['server_ip']
STRINGS_PATH = DIR + config['language'] + '.yml'
STRINGS = YAML.load_file STRINGS_PATH
DB_PATH = DIR + 'db' + File::SEPARATOR + hostname
if File.exists?(DB_PATH)
  records = Marshal.load(File.binread(DB_PATH))
else
  records = []
end
ort = Ort.new

def t(key, args = [])
  sprintf STRINGS[key], *args
end
def clear
  system 'clear'
end
def cursor(setting)
  system "setterm -cursor #{setting}"
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
def press_any_key_to_continue
  print t('press_any_key_to_continue')
  cursor 'on'
  read_char
  cursor 'off'
end
def selector(options, before = '', after = '')
  choice = 0
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
def sort(records)
  records.sort! do |a, b|
    [b.good, a.bad, a.time] <=> [a.good, b.bad, b.time]
  end
end

loop do
  begin
    cursor 'off'
    choice = selector [t('play'), t('results'), t('exit')], t('welcome')
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
          word = ort.get_word
          forms = ort.get_forms(word)
          if forms.size >= MIN_FORM_SIZE
            break
          end
        end
        answer = selector forms, t('status_and_choose', [good, bad, Time.at(seconds_left).utc.strftime('%M:%S')])
        if forms[answer] == word
          puts t('correct')
          good += 1
        else
          puts t('uncorrect') + word.chomp.bold
          bad += 1
        end
        press_any_key_to_continue
      end
    when 1
      clear
      unless records.empty?
        sort records
        rows, cols = $stdin.winsize
        rows = rows - 3
        nickname_length = cols - 45
        format = "  %#{nickname_length}s  |  %16s  |  %5s  |  %5s  \n"
        printf format, t('nickname'), t('when'), t('good'), t('bad')
        puts '-' * cols
        many = rows > records.size ? records.size : rows
        many.times do |i|
          record = records[i]
          printf format, record.name, record.time.strftime("%Y-%m-%d %H:%M"), record.good, record.bad
        end
      else
        puts t('nobody_played')
      end
      press_any_key_to_continue
    else
      exit
    end
  rescue EndGame
    record = Record.new(name, Time.now, good, bad)
    records << record
    sort records
    File.open(DB_PATH, 'wb') do |f|
      f.write(Marshal.dump(records))
    end
    clear
    puts t('position', [records.index(record) + 1])
    puts t('result', [good, bad])
    press_any_key_to_continue
  rescue SystemExit
    clear
    exit
  end
end