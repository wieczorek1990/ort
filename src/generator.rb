# encoding: UTF-8
require_relative 'conf'
require_relative 'string'
include Conf

class Generator
  CHANGES = {
    'ch' => 'h', 'h' => 'ch',
    'ż' => 'rz', 'rz' => 'ż',
    'ó' => 'u', 'u' => 'ó'
  }
  SINGLES = CHANGES.keys.select { |c| c.length == 1 }
  CLUSTERS = CHANGES.keys.select { |c| c.length == 2 }
  BIG = %w(Ą Ć Ę Ł Ń Ó Ś Ż Ź)
  DICT = File.readlines(DATA_PATH + 'pl_PL.dic')
  ORT_MAX = config 'ort_max'
  def self.get_word
    DICT.sample.chomp
  end
  def self.get_forms(word)
    capitalized = (not (/[A-Z]/ =~ word[0]).nil?) or BIG.include? word[0]
    w = word.downcase
    result = []
    tokens = []
    orts = []
    begin
      token_no = 0
      skip = false
      (0...w.length).each do |i|
        if skip
          skip = false
          next
        end
        char = w[i]
        cluster = w[i..i+1]
        if cluster.size == 2 and CLUSTERS.include? cluster
          tokens << cluster
          orts << { cluster => token_no }
          skip = true
        else
          if SINGLES.include? char
            orts << { char => token_no }
          end
          tokens << char
        end
        token_no += 1
      end
    end
    orts_size = orts.size
    orts_size = orts_size > ORT_MAX ? ORT_MAX : orts_size
    orts = orts.shuffle!.first(orts_size)
    for i in 0...(2 ** orts_size)
      orts_i = 0
      t = tokens.clone
      for j in (0..orts_size).map{ |k| 2 ** k }
        if i & j == j
          ort, pos = orts[orts_i].first
          t[pos] = CHANGES[ort]
        end
        orts_i += 1
      end
      result << t.join('')
    end
    if capitalized
      result.map! { |w| w.capitalize }
    end
    result.shuffle
  end
end