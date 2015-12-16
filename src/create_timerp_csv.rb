require 'csv'
require File.expand_path(File.dirname(__FILE__)) + '/new/common'
require File.expand_path(File.dirname(__FILE__)) + '/new/rankprestige'
require File.expand_path(File.dirname(__FILE__)) + '/new/urls_id_rp'

class CreateTimerpCsv
  include Common

  def initialize
    print_file_name

    create_rankprestiges_and_urls_ids_days
  end

  def run
    # １日目のurls_idごとにCSVを作る
    date = START_DATE
    @urls_ids_days[date - START_DATE].values.each do |urls_id|
      print_variable(urls_id: urls_id, date: date)
      create_csv(urls_id)
    end
  end

  def create_csv(create_urls_id)
    result_csv = []

    # 指定されたurls_idのPRを日付ごとに格納する
    START_DATE.upto(END_DATE) do |date|
      rankprestige = getrankprestige_from_adminid(date, getadminid_from_urlsid(date, create_urls_id))
      #print_variable({date: date, rankprestige: rankprestige})

      result_csv.push([rankprestige])
    end

    write_file_name = "timerankprestige_#{PAGE}_from#{START_DATE.yday}to#{END_DATE.yday}_#{create_urls_id}.txt"

    CSV.open("#{RESULTFILE_DIR}timerankprestige/#{write_file_name}", 'w') do |write_file|
      result_csv.each do |row|
        write_file << row
      end
    end
  end

  private
  def print_file_name
    p "**** #{File.basename(__FILE__)} ****"
    LOG.info("**** #{File.basename(__FILE__)} ****")
  end

  def getadminid_from_urlsid(date, urls_id)
    urls_id_index = @urls_ids_days[date - START_DATE].values.find_index { |urls_id_by_date| urls_id_by_date == urls_id }
    urls_id_index.nil? ? nil : (urls_id_index + 1)
  end

  def getrankprestige_from_adminid(date, admin_id)
    return nil if admin_id.nil?
    rankprestige_index = admin_id - 1
    @rankprestiges_days[date - START_DATE].values[rankprestige_index]
  end

  def create_rankprestiges_and_urls_ids_days
    ### 各日のrankprestigesとurls_idsを紐付ける
    @rankprestiges_days = []
    @urls_ids_days = []

    START_DATE.upto(END_DATE) do |date|
      print_dateline(date)

      if SKIP_DATES.include?(date)
        p "#{date} skipped.(#{PAGE})"
        LOG.info("#{date} skipped.(#{PAGE})")
        next
      end

      rankprestiges = Rankprestige.new(date)
      rankprestiges.read

      urls_id_rps = UrlsIdRp.new(date)
      urls_id_rps.find(rankprestiges.values.size)

      print_variable(rankprestiges_size: rankprestiges.values.size, urls_id_rps_size: urls_id_rps.values.size)

      @rankprestiges_days.push(rankprestiges)
      @urls_ids_days.push(urls_id_rps)

      print_line
    end
  end
end
