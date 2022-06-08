require_relative 'game'

is_test_mode = ARGV[0] == 'test' ? true : false
Game.new(is_test_mode).run
