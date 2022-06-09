require_relative 'configuration'

include Configuration

# Generation of orts
class Generator
  CHANGES = {
    'ch' => 'h', 'h' => 'ch',
    'ż' => 'rz', 'rz' => 'ż',
    'ó' => 'u', 'u' => 'ó'
  }.freeze
  SINGLES = CHANGES.keys.select { |c| c.length == 1 }
  CLUSTERS = CHANGES.keys.select { |c| c.length == 2 }
  BIG = %w[Ą Ć Ę Ł Ń Ó Ś Ż Ź].freeze
  DICT = File.readlines("#{DATA_PATH}pl_PL.dic", encoding: 'utf-8')
  ORT_MAX = config 'ort_max'

  def self.sample_word
    DICT.sample.chomp
  end

  def self.gen_forms(word)
    capitalized = !(/[A-Z]/ =~ word[0]).nil? || BIG.include?(word[0])
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
        cluster = w[i..i + 1]
        if cluster.size == 2 && CLUSTERS.include?(cluster)
          tokens << cluster
          orts << { cluster => token_no }
          skip = true
        else
          orts << { char => token_no } if SINGLES.include? char
          tokens << char
        end
        token_no += 1
      end
    end
    orts_size = orts.size
    orts_size = ORT_MAX if orts_size > ORT_MAX
    orts = orts.shuffle!.first(orts_size)
    (0...(2**orts_size)).each do |i|
      ort_no = 0
      t = tokens.clone
      (0..orts_size).map { |k| 2**k }.each do |j|
        if i & j == j
          ort, pos = orts[ort_no].first
          t[pos] = CHANGES[ort]
        end
        ort_no += 1
      end
      result << t.join
    end
    result.map!(&:capitalize) if capitalized
    result.shuffle
  end
end
