# encoding: UTF-8
class Ort
  DICT_PATH = File.dirname(__FILE__) + File::SEPARATOR + 'pl_PL.dic'
  ORTS = ['ch', 'h', 'ż', 'rz', 'ó', 'u']
  CHANGES = {
    'ch' => 'h', 'h' => 'ch',
    'ż' => 'rz', 'rz' => 'ż',
    'ó' => 'u', 'u' => 'ó',
  }
  SEQ_MAX = 3
  def initialize
    @dict = File.readlines(DICT_PATH)
  end
  def get_word
    return @dict.sample.chomp
  end
  def get_forms(word)
    result = []
    seqs = []
    for seq in ORTS
      if word.include?(seq)
        seqs << seq
      end
    end
    if seqs.include?('h') and seqs.include?('ch')
      seqs.delete('h')
    end
    seqs_size = seqs.size
    seqs_size = seqs_size > SEQ_MAX ? SEQ_MAX : seqs_size
    seqs.shuffle.first(seqs_size)
    for i in 0..2**seqs_size - 1
      l = 0
      w = word.clone
      for j in (0..seqs_size).map{ |k| 2**k }
        if i & j == j
          seq = seqs[l]
          w.sub!(seq, CHANGES[seq])
        end
        l += 1
      end
      result << w.chomp
    end
    return result.shuffle
  end
end
