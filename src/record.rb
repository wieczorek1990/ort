# -*- encoding : utf-8 -*-
require 'json'
require 'time'
include Conf

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
  def marshal_load array
    @name, @time, @good, @bad = array
  end
  def ==(o)
    o.class == self.class and o.marshal_dump == marshal_dump
  end
  def <=>(o)
    [o.points, o.good, @bad, @time] <=> [points, @good, @bad, o.time]
  end
  def self.load(db_path)
    if File.exists?(db_path)
      Marshal.load(File.binread(db_path))
    else
      []
    end
  end
  def self.save(db_path, records)
    unless Dir.exists? DB_PATH
      Dir.mkdir DB_PATH
    end
    File.open(db_path, 'wb') do |f|
      f.write(Marshal.dump(records))
    end
  end
  def to_json(options = {})
    { 'name' => @name, 'time' => @time, 'good' => @good, 'bad' => @bad }.to_json
  end
  def self.from_json string
    result = []
    data = JSON.restore string
    data = [data] if data.kind_of? Hash
    data.each do |item|
      result << self.new(item['name'], Time.parse(item['time']), item['good'], item['bad'])
    end
    result
  end
end