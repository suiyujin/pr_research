require 'csv'
require File.expand_path(File.dirname(__FILE__)) + '/new/common'

class FindRisePage
  include Common

  def initialize
    @rise_urls_ids = Array.new
  end

  def run
    Dir::foreach(RESULTFILE_DIR + 'timepagerank/') do |timepagerank_file|
      next if timepagerank_file == "." || timepagerank_file == ".."

      values = []
      File::open(RESULTFILE_DIR + 'timepagerank/' + timepagerank_file, 'r') do |f|
        f.each_line do |line|
          values << line.chomp
        end
      end

      # 最初と最後のPRを比べて、2倍以上となっているurls_idを調べる
      if (values.last.to_f / values.first.to_f) >= 2.0
        urls_id = timepagerank_file.match(/^.+\_(\d+)\.txt$/)[1].to_i
        print_variable({rise_urls_id: urls_id})
        @rise_urls_ids << urls_id
      end
    end

    write_file_name = "rise_urls_ids_#{PAGE}_from#{START_DATE.yday}to#{END_DATE.yday}.txt"
    
    CSV.open("#{RESULTFILE_DIR}timepagerank/#{write_file_name}", 'w') do |write_file|
      write_file << @rise_urls_ids
    end

  end
end
