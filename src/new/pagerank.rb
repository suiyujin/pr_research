require File.expand_path(File.dirname(__FILE__)) + '/common'

class Pagerank
  include Common

  attr_reader :values

  def initialize(date)
    @date = date
  end

  def read
    print_variable(pageranksfile_name: make_file_name)

    File::open(RESULTFILE_DIR + make_file_name, "r") do |f|
      @values = matlab? ? f.readlines[0].chomp.split : f.readlines[5].chomp.split
    end
  end

  private
  def make_file_name
    if @date.year == START_DATE.year
      return "pagerank_#{PAGE}_#{@date.yday}_from#{START_DATE.yday}to#{END_DATE.yday}.txt"
    else
      # 年が変化している場合はydayへ前年分の日数を加える
      file_yday = Date.leap?(START_DATE.year) ? (@date.yday + 366) : (@date.yday + 365)
      return "pagerank_#{PAGE}_#{file_yday}_from#{START_DATE.yday}to#{END_DATE.yday}.txt"
    end
  end

end
