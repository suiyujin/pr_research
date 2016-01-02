require File.expand_path(File.dirname(__FILE__)) + '/new/common'
require 'rubyXL'

class MakeXlsxFile
  include Common

  def initialize(target: 'pagerank')
    print_file_name

    p "target: #{target}"
    @target = target
  end

  def run
    TH_MORE_INCS.each do |th_more_inc|
      # check_apk, check_rkファイルを読み込む
      if TAIL_OF_FILE == '_penaltyq'
        read_file_name = "#{@target}_a#{A_DATE}_b#{B_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_#{CHECK_FLAG}_#{REDUCE_WEIGHT.to_i}reduce_#{LIMIT_DESC_RATE.to_i}desc_#{LIMIT_DOWN_RATE.to_i}#{TAIL_OF_FILE}.csv"
        apk_file_path = "#{RESULTFILE_DIR}check_apk/#{read_file_name}"
        rk_file_path = "#{RESULTFILE_DIR}check_rk/#{read_file_name}"
      else
        read_file_name = "#{@target}_a#{A_DATE}_b#{B_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_#{CHECK_FLAG}_#{REDUCE_WEIGHT.to_i}reduce_#{LIMIT_DOWN_RATE.to_i}#{TAIL_OF_FILE}.csv"
        apk_file_path = "#{RESULTFILE_DIR}check_apk/#{read_file_name}"
        rk_file_path = "#{RESULTFILE_DIR}check_rk/#{read_file_name}"
      end

      result_apk = []
      result_rk = []

      File.open(apk_file_path, 'r') { |f| result_apk = f.read.split("\n") }

      p "#{apk_file_path} read."
      LOG.info("#{apk_file_path} read.")

      File.open(rk_file_path, 'r') { |f| result_rk = f.read.split("\n") }

      p "#{rk_file_path} read."
      LOG.info("#{rk_file_path} read.")

      p "result_apk.size: #{result_apk.size}"
      LOG.info("result_apk.size: #{result_apk.size}")
      p "result_rk.size: #{result_rk.size}"
      LOG.info("result_rk.size: #{result_rk.size}")

      # xlsxファイルを作成する
      workbook = RubyXL::Workbook.new
      worksheet = workbook[0]

      # 情報を書き込む
      worksheet.add_cell(0, 0, 'a_date')
      worksheet.add_cell(0, 1, A_DATE)
      worksheet.add_cell(1, 0, 'b_date')
      worksheet.add_cell(1, 1, B_DATE)
      worksheet.add_cell(2, 0, 'times')
      worksheet.add_cell(2, 1, th_more_inc)
      worksheet.add_cell(3, 0, 'page')
      worksheet.add_cell(3, 1, PAGE)
      worksheet.add_cell(4, 0, 'start_date')
      worksheet.add_cell(4, 1, START_DATE)
      worksheet.add_cell(5, 0, 'end_date')
      worksheet.add_cell(5, 1, END_DATE)
      worksheet.add_cell(6, 0, 'check_flag')
      worksheet.add_cell(6, 1, CHECK_FLAG)
      worksheet.add_cell(7, 0, 'reduce_weight')
      worksheet.add_cell(7, 1, REDUCE_WEIGHT)
      worksheet.add_cell(8, 0, 'limit_down_rate')
      worksheet.add_cell(8, 1, LIMIT_DOWN_RATE)
      worksheet.add_cell(9, 0, 'limit_desc_rate')
      worksheet.add_cell(9, 1, LIMIT_DESC_RATE)

      # dataを書き込む
      worksheet.add_cell(0, 3, 'k')
      worksheet.add_cell(0, 4, 'recall')
      worksheet.add_cell(0, 5, 'precision')

      # k
      result_apk.size.times do |time|
        row_index = k = time + 1
        worksheet.add_cell(row_index, 3, k)
      end

      # recall
      result_rk.each.with_index(1) do |result, row_index|
        worksheet.add_cell(row_index, 4, result.to_f)
      end
      # precision
      result_apk.each.with_index(1) do |result, row_index|
        worksheet.add_cell(row_index, 5, result.to_f)
      end

      # xlsxファイルを保存する
      if TAIL_OF_FILE == '_penaltyq'
        result_file_path = "#{RESULTFILE_DIR}xlsx/#{@target}_a#{A_DATE}_b#{B_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_#{CHECK_FLAG}_#{REDUCE_WEIGHT.to_i}reduce_#{LIMIT_DESC_RATE.to_i}desc_#{LIMIT_DOWN_RATE.to_i}#{TAIL_OF_FILE}.xlsx"
      else
        result_file_path = "#{RESULTFILE_DIR}xlsx/#{@target}_a#{A_DATE}_b#{B_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_#{CHECK_FLAG}_#{REDUCE_WEIGHT.to_i}reduce_#{LIMIT_DOWN_RATE.to_i}#{TAIL_OF_FILE}.xlsx"
      end

      workbook.write(result_file_path)

      p "#{result_file_path} writed."
      LOG.info("#{result_file_path} writed.")

    end # th_more_incs
  end

  def print_file_name
    p "**** #{File.basename(__FILE__)} ****"
    LOG.info("**** #{File.basename(__FILE__)} ****")
  end
end
