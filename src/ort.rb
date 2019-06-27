require_relative 'game'

TEST = ARGV[0] == 'test' ? true : false
Game.new(TEST).run