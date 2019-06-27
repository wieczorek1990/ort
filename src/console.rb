require 'colorize'
require 'highline/system_extensions' if Gem.win_platform?
require 'io/console'

module Console
  def clean_exit
    cursor 'on'
    clear
    exit
  end

  def clear
    system('clear') || system('cls')
  end

  # TODO: Find Windows equivalent
  def cursor(setting)
    case setting
    when 'on'
      system 'tput cnorm'
    when 'off'
      system 'tput civis'
    end
  end

  def read_char
    if Gem.win_platform?
      multibyte_char = []
      multibyte_char << HighLine::SystemExtensions.get_character
      if [0, 224].include? multibyte_char[0]
        multibyte_char << HighLine::SystemExtensions.get_character
      end
      multibyte_char = multibyte_char[0] if multibyte_char.size == 1
      multibyte_char
    else
      # TODO: Find another method
      begin
        STDIN.echo = false
        STDIN.raw!
        input = STDIN.getc.chr
        if input == "\e"
          begin
            input << STDIN.read_nonblock(3)
          rescue nil
            nil
          end
        end
      ensure
        STDIN.echo = true
        STDIN.cooked!
      end
      input
    end
  end

  def selector(options, extra = {})
    def prev_choice(choice, last)
      choice - 1 < 0 ? last : choice - 1
    end

    def next_choice(choice, last)
      choice + 1 > last ? 0 : choice + 1
    end
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
      c = read_char
      if Gem.win_platform?
        case c
        # enter, space
        when 13, 32
          return choice
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
        case c
        # enter, space
        when "\r", ' '
          return choice
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
    end
  end
end