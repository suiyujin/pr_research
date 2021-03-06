require File.expand_path(File.dirname(__FILE__)) + '/new/common'

class CheckApk
  include Common

  def initialize(target: 'pagerank')
    print_file_name

    p "target: #{target}"
    @target = target
  end

  def run
    TH_MORE_INCS.each do |th_more_inc|
      # check_pkファイルを読み込む
      if TAIL_OF_FILE == '_penaltyq'
        read_file_name = "#{RESULTFILE_DIR}check_pk/#{@target}_a#{A_DATE}_b#{B_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_#{CHECK_FLAG}_#{REDUCE_WEIGHT.to_i}reduce_#{LIMIT_DESC_RATE.to_i}desc_#{LIMIT_DOWN_RATE.to_i}#{TAIL_OF_FILE}.csv"
      else
        read_file_name = "#{RESULTFILE_DIR}check_pk/#{@target}_a#{A_DATE}_b#{B_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_#{CHECK_FLAG}_#{REDUCE_WEIGHT.to_i}reduce_#{LIMIT_DOWN_RATE.to_i}#{TAIL_OF_FILE}.csv"
      end

      result_urls_ids = Array.new
      result_check = Array.new
      result_check_aves = Array.new

      File.open(read_file_name, 'r') do |read_file|
        urls_ids_str, check_str = read_file.readlines
        result_urls_ids = urls_ids_str.chomp.split(',')
        result_check = check_str.chomp.split(',')
      end

      p "#{read_file_name} read."
      LOG.info("#{read_file_name} read.")

      p "result_urls_ids.size: #{result_urls_ids.size}"
      LOG.info("result_urls_ids.size: #{result_urls_ids.size}")

      # result_check配列から平均適合率を計算する
      result_check.size.times do |index|
        sum = 0.0
        0.upto(index) do |i|
          sum += result_check[i].to_f
        end
        ave = sum / (index + 1)
        result_check_aves << ave
      end

      if TAIL_OF_FILE == '_penaltyq'
        result_file_name = "#{RESULTFILE_DIR}check_apk/#{@target}_a#{A_DATE}_b#{B_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_#{CHECK_FLAG}_#{REDUCE_WEIGHT.to_i}reduce_#{LIMIT_DESC_RATE.to_i}desc_#{LIMIT_DOWN_RATE.to_i}#{TAIL_OF_FILE}.csv"
      else
        result_file_name = "#{RESULTFILE_DIR}check_apk/#{@target}_a#{A_DATE}_b#{B_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_#{CHECK_FLAG}_#{REDUCE_WEIGHT.to_i}reduce_#{LIMIT_DOWN_RATE.to_i}#{TAIL_OF_FILE}.csv"
      end

      File.open(result_file_name, 'w') do |result_file|
        result_check_aves.each do |result_check_ave|
          result_file.write(result_check_ave)
          result_file.write("\n")
        end
      end

      p "#{result_file_name} writed."
      LOG.info("#{result_file_name} writed.")

    end # th_more_incs
  end

  def print_file_name
    p "**** #{File.basename(__FILE__)} ****"
    LOG.info("**** #{File.basename(__FILE__)} ****")
  end
end
