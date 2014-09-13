require 'io/console'
require_relative 'string'

module Console
  def clean_exit
    cursor 'on'
    clear
    exit
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
end