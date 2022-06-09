# Selector helper exception
class SelectorExit < StandardError
  attr_reader :choice

  def initialize(choice)
    @choice = choice
    super
  end
end

# Socket connection issues error
class NoConnection < StandardError
end
