require 'colorize'
require 'highline/system_extensions' if Gem.win_platform?

require_relative 'exceptions'

# Terminal operations
module Console
  def clean_exit
    cursor 'on'
    clear
    exit
  end

  def clear
    system('clear') || system('cls')
  end

  def cursor(setting)
    return if Gem.win_platform?
    case setting
    when 'on'
      system 'tput cnorm'
    when 'off'
      system 'tput civis'
    else
      raise Exception 'Invalid value for cursor setting!'
    end
  end

  def get_character
    if Gem.win_platform?
      HighLine::SystemExtensions.get_character
    else
      STDIN.getch
    end
  end

  def read_keystroke
    if Gem.win_platform?
      input = []
      character = get_character
      input << character
      if [0, 224].include? character
        input << get_character
      end
      if input.size == 1
        character
      else
        input
      end
    else
      input = get_character
      if input == "\e"
        begin
          input << STDIN.read_nonblock(3)
        rescue nil
          nil
        end
      end
      input
    end
  end

  def prev_choice(choice, last)
    choice - 1 < 0 ? last : choice - 1
  end

  def next_choice(choice, last)
    choice + 1 > last ? 0 : choice + 1
  end

  def get_choice(keystroke, last, choice)
    if Gem.win_platform?
      case keystroke
      # enter, space
      when 13, 32
        raise SelectorExit.new(choice)
      # esc, ctrl+c
      when 27, 3
        clean_exit
      # up
      when [0, 72], [224, 72]
        choice = prev_choice(choice, last)
      # down
      when [0, 80], [224, 80]
        choice = next_choice(choice, last)
      else
        nil
      end
    else
      case keystroke
      # enter, space
      when "\r", ' '
        raise SelectorExit.new(choice)
      # esc, ctrl+c
      when "\e", "\u0003"
        clean_exit
      # up
      when "\e[A"
        choice = prev_choice(choice, last)
      # down
      when "\e[B"
        choice = next_choice(choice, last)
      else
        nil
      end
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
        if i != choice
          puts line
        else
          puts line.swap
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
