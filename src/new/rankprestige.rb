require File.expand_path(File.dirname(__FILE__)) + '/common'

class Rankprestige
  include Common

  attr_reader :values

  def initialize(date)
    @date = date
  end

  def read
    print_variable(rankprestige_file_name: make_file_name)

    File::open(RESULT_MATLAB_DIR + make_file_name, "r") do |f|
      @values = f.readlines[0].chomp.split
    end
  end

  private
  def make_file_name
    "rankprestige_#{@date.strftime('%Y%m%d')}_limit#{LIMIT_SEEDS_NUM}.txt"
  end
end
