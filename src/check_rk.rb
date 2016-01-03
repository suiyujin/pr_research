require File.expand_path(File.dirname(__FILE__)) + '/new/common'

class CheckRk
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
        default_file_name = "#{RESULTFILE_DIR}check_pk/#{@target}_a#{A_DATE}_b#{B_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_#{CHECK_FLAG}_#{REDUCE_WEIGHT.to_i}reduce_#{LIMIT_DOWN_RATE.to_i}#{TAIL_OF_FILE}.csv"
      else
        read_file_name = "#{RESULTFILE_DIR}check_pk/#{@target}_a#{A_DATE}_b#{B_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_#{CHECK_FLAG}_#{REDUCE_WEIGHT.to_i}reduce_#{LIMIT_DOWN_RATE.to_i}#{TAIL_OF_FILE}.csv"
      end

      result_urls_ids = []
      result_check = []

      File.open(read_file_name, 'r') do |read_file|
        urls_ids_str, check_str = read_file.readlines
        result_urls_ids = urls_ids_str.chomp.split(',')
        result_check = check_str.chomp.split(',')
      end

      p "#{read_file_name} read."
      LOG.info("#{read_file_name} read.")

      p "result_urls_ids.size: #{result_urls_ids.size}"
      LOG.info("result_urls_ids.size: #{result_urls_ids.size}")

      # result_check配列から再現率を計算する
      if TAIL_OF_FILE == '_penaltyq'
        default_urls_ids = []
        default_check = []

        File.open(default_file_name, 'r') do |default_file|
          urls_ids_str, check_str = default_file.readlines
          default_urls_ids = urls_ids_str.chomp.split(',')
          default_check = check_str.chomp.split(',')
        end

        p "#{default_file_name} read."
        LOG.info("#{default_file_name} read.")

        p "default_urls_ids.size: #{default_urls_ids.size}"
        LOG.info("default_urls_ids.size: #{default_urls_ids.size}")

        # collect_countをdefaultの正解数にする
        collect_count = default_check.count { |result| result == '1' }
      else
        collect_count = result_check.count { |result| result == '1' }
      end

      result_check_rs = result_check.size.times.map do |index|
        result_check[0..index].map(&:to_i).inject(:+).to_f / collect_count.to_f
      end

      if TAIL_OF_FILE == '_penaltyq'
        result_file_name = "#{RESULTFILE_DIR}check_rk/#{@target}_a#{A_DATE}_b#{B_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_#{CHECK_FLAG}_#{REDUCE_WEIGHT.to_i}reduce_#{LIMIT_DESC_RATE.to_i}desc_#{LIMIT_DOWN_RATE.to_i}#{TAIL_OF_FILE}.csv"
      else
        result_file_name = "#{RESULTFILE_DIR}check_rk/#{@target}_a#{A_DATE}_b#{B_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_#{CHECK_FLAG}_#{REDUCE_WEIGHT.to_i}reduce_#{LIMIT_DOWN_RATE.to_i}#{TAIL_OF_FILE}.csv"
      end

      File.open(result_file_name, 'w') do |result_file|
        result_check_rs.each { |result_check_r| result_file.write("#{result_check_r}\n") }
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
