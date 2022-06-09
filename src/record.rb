require 'json'
require 'time'

include Configuration

# Results as records
class Record
  include Comparable
  attr_reader :name, :time, :good, :bad

  def initialize(name, time, good, bad)
    @name = name
    @time = time
    @good = good
    @bad = bad
  end

  def points
    @good - @bad
  end

  def marshal_dump
    [@name, @time, @good, @bad]
  end

  def marshal_load(array)
    @name, @time, @good, @bad = array
  end

  def ==(other)
    other.class == self.class && other.marshal_dump == marshal_dump
  end

  def <=>(other)
    [other.points, other.good, @bad, @time] <=>
      [points, @good, @bad, other.time]
  end

  def self.load(db_path)
    if File.exist?(db_path)
      Marshal.load(File.binread(db_path))
    else
      []
    end
  end

  def self.save(db_path, records)
    Dir.mkdir DB_PATH unless Dir.exist? DB_PATH
    File.binwrite(db_path, Marshal.dump(records))
  end

  def to_json(options = {})
    {
      name: @name, time: @time,
      good: @good, bad: @bad
    }.to_json(options)
  end

  def self.from_json(string)
    result = []
    data = JSON.parse string
    data = [data] if data.is_a? Hash
    data.each do |item|
      result << new(item['name'],
                    Time.parse(item['time']),
                    item['good'],
                    item['bad'])
    end
    result
  end
end
