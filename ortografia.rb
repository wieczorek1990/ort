#!/usr/bin/ruby
# encoding: UTF-8
# http://pl.wikipedia.org/wiki/Pomoc:Powszechne_b%C5%82%C4%99dy_j%C4%99zykowe
require 'thread'
require_relative 'ort.rb'
def clear
  system 'clear'
end
def press_any_key
  puts 'Naciśnij dowolny klawisz, aby kontynuować...'
  gets
end
class String
  def bold
    "\033[1m#{self}\033[22m"
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
ROUND_SECONDS=5*60

ort = Ort.new
if File.exists?('db')
  records = Marshal.load(File.binread('db'))
else
  records = []
end
reader = nil
loop do
  begin
    choice = 0
    loop do
      clear
      puts 'Witaj w programie do nauki ortografi!'
      puts 'Wybierz co chcesz zrobić:'
      puts '1) Graj'
      puts '2) Wyniki'
      puts '3) Wyjście'
      print 'Wybór: '
      choice = gets.chomp.to_i
      if (1..3).include?(choice)
        break
      end
    end
    if choice == 1
      time_queue = Queue.new
      answer_queue = Queue.new
      points = 0
      good = 0
      bad = 0
      name = ''
      seconds_left = ROUND_SECONDS
      loop do
        print 'Podaj swoje imię: '
        name = gets.chomp
        if name.length > 2
          break
        else
          puts 'Niepoprawne imie!'
        end
      end
      timer = Thread.new {
        while seconds_left > 0
          sleep 1
          seconds_left -= 1
          time_queue.clear
          time_queue << seconds_left
        end
        exit
      }
      loop do
        forms = []
        word = ''
        loop do
          word = ort.get_word
          forms = ort.get_forms(word)
          if forms.size > 2
            break
          end
        end
        loop do
          reader = Thread.new {
            answer = $stdin.gets.chomp.to_i
            answer_queue.clear
            answer_queue << answer
          }
          clear
          puts 'Punkty: ' + points.to_s + '. Pozostały czas: ' + Time.at(time_queue.pop).utc.strftime('%M:%S') + '.'
          puts 'Wybierz poprawnę formę:'
          ort.print_forms(forms)
          print 'Odpowiedź: '
          unless answer_queue.empty?
            answer = answer_queue.pop
            unless (1..forms.size).include?(answer)
              puts 'Zły numer odpowiedzi. Spróbuj ponownie.'
            else
              puts word.chomp.bold
              if forms[answer - 1] == word
                puts 'Brawo! Wybrałeś poprawną odpowiedź. +2 punkty'
                points += 2
                good += 1
              else
                puts 'Zła odpowiedź. Musisz się lepiej postarać następnym razem. -1 punkt'
                points -= 1
                bad += 1
              end
              reader.exit
              press_any_key
              break
            end
          end
          sleep 1
          reader.exit
        end
      end
    elsif choice == 2
      unless records.empty?
        puts 'Wyniki'.bold
        format = "%30s\t%16s\t%5s\n"
        printf format.bold, 'Imię', 'Kiedy', 'Punkty'
        records.each do |record|
          printf format, record.name, record.time.strftime("%Y-%m-%d %H:%M"), record.points
        end
      else
        puts 'Jeszcze tutaj nie grano.'
      end
      press_any_key
    else
      exit
    end
  rescue Interrupt, SystemExit
      if choice == 1
        reader.exit unless reader.nil?
        clear
        puts 'Twój wynik to ' + points.to_s + ' punktów.'
        puts good.to_s + ' dobrych odpowiedzi oraz ' + bad.to_s + ' złych odpowiedzi.'
        records << Record.new(name, Time.now, points)
        records.sort_by! { |o| [o.points, o.time] }
        records.reverse!
        File.open('db', 'wb') do |f|
          f.write(Marshal.dump(records))
        end
      elsif choice == 3
        exit
      end
  end
end