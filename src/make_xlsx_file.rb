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
      # xlsxファイルを作成する
      workbook = RubyXL::Workbook.new
      worksheet = workbook[0]

      # 情報を書き込む
      write_info(worksheet, th_more_inc)
      if TAIL_OF_FILE == '_penaltyq'
        write_lavel_penaltyq(worksheet)
        limit_desc_rates = (PAGE == 'bbc' || PAGE == 'cnn') ? ['70', '80', '90'] : ['70', '75', '80', '90']

        # defaultファイル名
        default_file_name = "#{@target}_a#{A_DATE}_b#{B_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_#{CHECK_FLAG}_#{REDUCE_WEIGHT.to_i}reduce_#{LIMIT_DOWN_RATE.to_i}.csv"
        default_apk_file_path = "#{RESULTFILE_DIR}check_apk/#{default_file_name}"
        default_rk_file_path = "#{RESULTFILE_DIR}check_rk/#{default_file_name}"
      else
        write_lavel(worksheet)
        limit_desc_rates = ['']
      end

      limit_desc_rates.each_with_index do |limit_desc_rate, desc_index|
        # check_apk, check_rkファイルを読み込む
        if TAIL_OF_FILE == '_penaltyq'
          read_file_name = "#{@target}_a#{A_DATE}_b#{B_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_#{CHECK_FLAG}_#{REDUCE_WEIGHT.to_i}reduce_#{limit_desc_rate}desc_#{LIMIT_DOWN_RATE.to_i}#{TAIL_OF_FILE}.csv"
          apk_file_path = "#{RESULTFILE_DIR}check_apk/#{read_file_name}"
          rk_file_path = "#{RESULTFILE_DIR}check_rk/#{read_file_name}"
        else
          read_file_name = "#{@target}_a#{A_DATE}_b#{B_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_#{CHECK_FLAG}_#{REDUCE_WEIGHT.to_i}reduce_#{LIMIT_DOWN_RATE.to_i}#{TAIL_OF_FILE}.csv"
          apk_file_path = "#{RESULTFILE_DIR}check_apk/#{read_file_name}"
          rk_file_path = "#{RESULTFILE_DIR}check_rk/#{read_file_name}"
        end

        result_apk = read_file(apk_file_path)
        result_rk = read_file(rk_file_path)

        p "result_apk.size: #{result_apk.size}"
        LOG.info("result_apk.size: #{result_apk.size}")
        p "result_rk.size: #{result_rk.size}"
        LOG.info("result_rk.size: #{result_rk.size}")

        # dataを書き込む
        if TAIL_OF_FILE == '_penaltyq'
          # recall
          write_data(worksheet, col_index: (5 + desc_index), row_start_index: 2, data: result_rk.map(&:to_f))
          # precision
          write_data(worksheet, col_index: (11 + desc_index), row_start_index: 2, data: result_apk.map(&:to_f))
        else
          # k
          write_data(worksheet, col_index: 3, row_start_index: 1, data: (1..result_apk.size).to_a)
          # recall
          write_data(worksheet, col_index: 4, row_start_index: 1, data: result_rk.map(&:to_f))
          # precision
          write_data(worksheet, col_index: 5, row_start_index: 1, data: result_apk.map(&:to_f))
        end
      end

      # kとdefaultを書き込む(penaltyq)
      if TAIL_OF_FILE == '_penaltyq' && default_apk_file_path && default_rk_file_path
        result_apk = read_file(default_apk_file_path)
        result_rk = read_file(default_rk_file_path)

        p "default result_apk.size: #{result_apk.size}"
        LOG.info("default result_apk.size: #{result_apk.size}")
        p "default result_rk.size: #{result_rk.size}"
        LOG.info("default result_rk.size: #{result_rk.size}")

        # k
        write_data(worksheet, col_index: 3, row_start_index: 2, data: (1..result_apk.size).to_a)
        # default recall
        write_data(worksheet, col_index: 4, row_start_index: 2, data: result_rk.map(&:to_f))
        # k
        write_data(worksheet, col_index: 9, row_start_index: 2, data: (1..result_apk.size).to_a)
        # default precision
        write_data(worksheet, col_index: 10, row_start_index: 2, data: result_apk.map(&:to_f))
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

  private

  def write_info(worksheet, th_more_inc)
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
  end

  def write_lavel(worksheet)
    worksheet.add_cell(0, 3, 'k')
    worksheet.add_cell(0, 4, 'recall')
    worksheet.add_cell(0, 5, 'precision')
  end

  def write_lavel_penaltyq(worksheet)
    worksheet.add_cell(0, 3, 'recall')
    worksheet.add_cell(0, 9, 'precision')

    worksheet.add_cell(1, 3, 'k')
    worksheet.add_cell(1, 4, 'default')
    worksheet.add_cell(1, 5, '70')
    worksheet.add_cell(1, 6, '75')
    worksheet.add_cell(1, 7, '80')
    worksheet.add_cell(1, 8, '90')

    worksheet.add_cell(1, 9, 'k')
    worksheet.add_cell(1, 10, 'default')
    worksheet.add_cell(1, 11, '70')
    worksheet.add_cell(1, 12, '75')
    worksheet.add_cell(1, 13, '80')
    worksheet.add_cell(1, 14, '90')
  end

  def write_data(worksheet, col_index:, row_start_index:, data:)
    data.each_with_index do |d, index|
      worksheet.add_cell((row_start_index + index), col_index, d)
    end
  end

  def read_file(file_path)
    return_ary = []
    File.open(file_path, 'r') { |f| return_ary = f.read.split("\n") }
    p "#{file_path} read."
    LOG.info("#{file_path} read.")

    return_ary
  end

  def print_file_name
    p "**** #{File.basename(__FILE__)} ****"
    LOG.info("**** #{File.basename(__FILE__)} ****")
  end
end
