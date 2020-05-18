#Implement a class called LineAnalyzer.
class LineAnalyzer
  attr_reader :highest_wf_count, :highest_wf_words, :content, :line_number
  def initialize(content, line_number)
    @content = content
    @line_number = line_number
    self.calculate_word_frequency
  end

  def calculate_word_frequency
    words_hash = Hash.new(0)
    @highest_wf_words = []
    @content.downcase.split.each do |word|
      words_hash[word] += 1
    end
    @highest_wf_count = words_hash.values.max
    @highest_wf_words = words_hash.select { |word, value| value == @highest_wf_count}.keys
  end
end

#  Implement a class called Solution. 
class Solution
  attr_reader :analyzers, :highest_count_across_lines, :highest_count_words_across_lines
  def initialize
    @analyzers = []
    
  end

  def analyze_file
    File.foreach('test.txt') do |line|
      analyzers << LineAnalyzer.new(line, $.)
    end
  end
  
  def calculate_line_with_highest_frequency
    @highest_count_words_across_lines = []
    @highest_count_across_lines = 0
   
    @analyzers.each do |l_analyzer_obj|
      @highest_count_across_lines = l_analyzer_obj.highest_wf_count if l_analyzer_obj.highest_wf_count > @highest_count_across_lines 
    end

    @analyzers.select do |l_analyzer_obj|
      @highest_count_words_across_lines.push(l_analyzer_obj) if l_analyzer_obj.highest_wf_count == @highest_count_across_lines
    end
  end

  def print_highest_word_frequency_across_lines
    puts "The following words have the highest word frequency per line:"
    @highest_count_words_across_lines.each do |w|
      puts "#{w.highest_wf_words} (appears) in line #{w.line_number}"
    end
  end
end
