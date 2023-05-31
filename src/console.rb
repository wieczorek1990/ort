require 'colorize'
require 'io/console' 

require_relative 'exceptions'

# Terminal operations
module Console
  def clean_exit
    cursor 'on'
    clear
    exit
  end

  def clear
    system('clear')
  end

  def cursor(setting)
    case setting
    when 'on'
      system 'tput cnorm'
    when 'off'
      system 'tput civis'
    else
      raise StandardError 'Invalid value for cursor setting!'
    end
  end

  def read_keystroke
    input = $stdin.getch
    if input == "\e" or input.ord == 224
      begin
        input << $stdin.read_nonblock(3)
      rescue StandardError
        nil
      end
    end
    input
  end

  def prev_choice(choice, last)
    (choice - 1).negative? ? last : choice - 1
  end

  def next_choice(choice, last)
    choice + 1 > last ? 0 : choice + 1
  end

  def get_choice(keystroke, last, choice)
    case keystroke
    # enter, space
    when "\r", ' '
      raise SelectorExit, choice
    # esc, ctrl+c
    when "\e", "\u0003"
      clean_exit
    end
    case keystroke
    # up
    when "\e[A", [224, 72]
      choice = prev_choice(choice, last)
    # down
    when "\e[B", [224, 80]
      choice = next_choice(choice, last)
    end
    choice
  end

  def selector(options, extra = {})
    before = extra[:before].nil? ? '' : extra[:before]
    after = extra[:after].nil? ? '' : extra[:after]
    choice = extra[:choice].nil? ? 0 : extra[:choice]
    last = options.size - 1
    loop do
      clear
      print before
      options.each_with_index do |line, i|
        line = line.yellow
        if i == choice
          puts line.swap
        else
          puts line
        end
      end
      print after
      keystroke = read_keystroke
      begin
        choice = get_choice(keystroke, last, choice)
      rescue SelectorExit => e
        return e.choice
      end
    end
  end
end
