# encoding: UTF-8
require_relative 'conf'
include Conf

class Ort
  DICT = File.readlines(File.dirname(__FILE__) + File::SEPARATOR + 'pl_PL.dic')
  ORTS = ['ch', 'h', 'ż', 'rz', 'ó', 'u']
  CHANGES = {
    'ch' => 'h', 'h' => 'ch',
    'ż' => 'rz', 'rz' => 'ż',
    'ó' => 'u', 'u' => 'ó',
  }
  ORT_MAX = conf 'ort_max'
  def self.get_word
    DICT.sample.chomp
  end
  def self.get_forms(word)
    result = []
    orts = []
    for ort in ORTS
      if word.include? ort
        orts << ort
      end
    end
    if orts.include?('h') and orts.include?('ch')
      orts.delete 'h'
    end
    orts_size = orts.size
    orts_size = orts_size > ORT_MAX ? ORT_MAX : orts_size
    orts.shuffle.first(orts_size)
    for i in 0...(2 ** orts_size)
      k = 0
      w = word.clone
      for j in (0..orts_size).map{ |l| 2 ** l }
        if i & j == j
          ort = orts[k]
          w.sub! ort, CHANGES[ort]
        end
        k += 1
      end
      result << w.chomp
    end
    result.shuffle
  end
end
