class String
  def bold
    "\033[1m#{self}\033[22m"
  end
  def highlight
    "\033[7m#{self}\033[27m"
  end
end