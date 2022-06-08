require_relative 'game'

is_test_mode = ARGV[0] == 'test'
Game.new(is_test_mode).run
