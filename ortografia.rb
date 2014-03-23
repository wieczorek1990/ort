#!/usr/bin/ruby
# encoding: UTF-8
# http://pl.wikipedia.org/wiki/Pomoc:Powszechne_b%C5%82%C4%99dy_j%C4%99zykowe
require_relative 'ort.rb'
def clear
  system 'clear'
end
points = 0
good = 0
bad = 0
begin
  clear
  puts 'Witaj w programie ORT do nauki ortografi!'
  loop do
    puts 'Masz ' + points.to_s + ' punktów.'
    forms = []
    word = ''
    loop do
      word = Ort.get_word
      forms = Ort.get_forms(word)
      if forms.size > 2
        break
      end
    end
    puts 'Wybierz poprawnę formę:'
    Ort.print_forms(forms)
    print 'Odpowiedź: '
    loop do
      answer = gets.chomp.to_i
      unless (1..forms.size).include?(answer)
        puts 'Zły numer odpowiedzi. Spróbuj ponownie.'
        print 'Odpowiedź: '
      else
        clear
        puts 'Poprawna odpowiedź to: ' + word.chomp
        if forms[answer - 1] == word
          puts 'Brawo!'
          points += 1
          good += 1
        else
          puts 'Zła odpowiedź. Musisz się lepiej postarać następnym razem.'
          points -= 0.5
          bad += 1
        end
        break
      end
    end
  end
  rescue Interrupt  
    clear
    puts 'Twój wynik to ' + points.to_s + ' punktów.'
    puts good.to_s + ' dobrych odpowiedzi oraz ' + bad.to_s + ' złych odpowiedzi.'
end
