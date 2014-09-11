#!/usr/bin/ruby
# encoding: UTF-8
require 'io/console'
require 'readline'
require 'thread'
require 'yaml'
require_relative 'ort.rb'
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
def press_to_continue
  print 'Naciśnij dowolny klawisz, aby kontynuować...'
  read_char
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
    [a.points, b.time] <=> [b.points, a.time]
  end
  records.reverse!
end
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
  attr_reader :name, :time, :points
  def initialize(name, time, points)
    @name = name
    @time = time
    @points = points
  end
  def marshal_dump
    [@name, @time, @points]
  end
  def marshal_load array
    @name, @time, @points = array
  end
end

DIR = File.dirname(__FILE__) + File::SEPARATOR
DB_PATH = DIR + 'db'
CONFIG_PATH = DIR + 'config.yml'
config = YAML.load_file CONFIG_PATH
ROUND_SECONDS = config['round_seconds']
MIN_FORM_SIZE = config['min_form_size']
INC = config['inc']
DEC = config['dec']
ort = Ort.new
if File.exists?(DB_PATH)
  records = Marshal.load(File.binread(DB_PATH))
else
  records = []
end

loop do
  begin
    cursor 'off'
    choice = selector ['Graj', 'Wyniki', 'Wyjście'], "Witaj w programie do nauki ortografi!\nReguły: dobra odpowiedź - +#{INC}, zła odpowiedź -#{DEC}.\nWybierz co chcesz zrobić:\n"
    if choice == 0
      points = 0
      good = 0
      bad = 0
      name = ''
      loop do
        clear
        cursor 'on'
        print 'Podaj swój pseudonim: '
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
        answer = selector forms, "Punkty #{points.to_s}. Dobre: #{good}. Złe: #{bad}. Pozostały czas: #{Time.at(seconds_left).utc.strftime('%M:%S')}.\nWybierz poprawną formę:\n"
        if forms[answer] == word
          puts 'Poprawnie!'
          points += INC
          good += 1
        else
          puts 'Niepoprawnie. Poprawna odpowiedź to: ' + word.chomp.bold
          points -= DEC
          bad += 1
        end
        press_to_continue
      end
    elsif choice == 1
      clear
      unless records.empty?
        sort records
        format = "%30s\t|\t%16s\t|\t%5s\n"
        rows, cols = $stdin.winsize
        rows = rows - 3
        printf format, 'Imię', 'Kiedy', 'Punkty'
        puts '-' * cols
        many = rows > records.size ? records.size : rows
        many.times do |i|
          record = records[i]
          printf format, record.name, record.time.strftime("%Y-%m-%d %H:%M"), record.points
        end
      else
        puts 'Jeszcze tutaj nie grano.'
      end
      press_to_continue
    else
      exit
    end
  rescue EndGame
    record = Record.new(name, Time.now, points)
    records << record
    sort records
    File.open(DB_PATH, 'wb') do |f|
      f.write(Marshal.dump(records))
    end
    clear
    puts 'Twój wynik to: ' + points.to_s + ' punktów.'
    puts good.to_s + ' dobrych odpowiedzi oraz ' + bad.to_s + ' złych odpowiedzi.'
    puts 'Jesteś ' + (records.index(record) + 1).to_s + '. na liście rekordów.'
    press_to_continue
  rescue SystemExit
    clear
    exit
  end
end
