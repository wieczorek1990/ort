require 'json'
require 'time'

class Record
  attr_reader :name, :time, :good, :bad
  def initialize(name, time, good, bad)
    @name = name
    @time = time
    @good = good
    @bad = bad
  end
  def marshal_dump
    [@name, @time, @good, @bad]
  end
  def marshal_load array
    @name, @time, @good, @bad = array
  end
  def self.sort(records)
    records.sort! do |a, b|
      [b.good, a.bad, a.time] <=> [a.good, b.bad, b.time]
    end
  end
  def self.load(db_path)
    if File.exists?(db_path)
      records = Marshal.load(File.binread(db_path))
    else
      records = []
    end
    records
  end
  def self.save(db_path, records)
    File.open(db_path, 'wb') do |f|
      f.write(Marshal.dump(records))
    end
  end
  def to_json
    {'name' => @name, 'time' => @time, 'good' => @good, 'bad' => @bad}.to_json
  end
  def self.from_json string
    data = JSON.load string
    self.new data['name'], Time.parse(data['time']), data['good'], data['bad']
  end
end