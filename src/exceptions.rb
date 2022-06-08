class SelectorExit < Exception
  attr_reader :choice

  def initialize(choice)
    @choice = choice
    super
  end
end
