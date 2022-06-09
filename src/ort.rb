require_relative 'games'

is_test_mode = ARGV[0] == 'test'
StandardTerminalGame.new(is_test_mode).run
