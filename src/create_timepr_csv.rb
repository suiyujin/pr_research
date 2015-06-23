require 'csv'
require File.expand_path(File.dirname(__FILE__)) + '/new/common'
require File.expand_path(File.dirname(__FILE__)) + '/new/pagerank'
require File.expand_path(File.dirname(__FILE__)) + '/new/urls_id'

class Create_timepr_csv
  include Common

  def initialize
    print_file_name

    create_pageranks_and_urls_ids_days
  end

  def run
    # １日目のurls_idごとにCSVを作る
    date = START_DATE
    @urls_ids_days[date - START_DATE].values.each do |urls_id|
      print_variable({urls_id: urls_id, date: date})
      create_csv(urls_id)
    end
  end

  def create_csv(create_urls_id)
    result_csv = Array.new

    # 指定されたurls_idのPRを日付ごとに格納する
    START_DATE.upto(END_DATE) do |date|
      pagerank = getpagerank_from_adminid(date, getadminid_from_urlsid(date, create_urls_id))
      #print_variable({date: date, pagerank: pagerank})

      result_csv.push([pagerank])
    end
    
    write_file_name = "timepagerank_#{PAGE}_from#{START_DATE.yday}to#{END_DATE.yday}_#{create_urls_id}.txt"

    CSV.open("#{RESULTFILE_DIR}timepagerank/#{write_file_name}", 'w') do |write_file|
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
    @urls_ids_days[date - START_DATE].values.find_index { |urls_id_by_date| urls_id_by_date == urls_id }
  end

  def getpagerank_from_adminid(date, admin_id)
    return nil if admin_id.nil?
    @pageranks_days[date - START_DATE].values[admin_id]
  end

  def create_pageranks_and_urls_ids_days
    ### 各日のpageranksとurls_idsを紐付ける
    @pageranks_days = Array.new
    @urls_ids_days = Array.new

    START_DATE.upto(END_DATE) do |date|
      print_dateline(date)

      if SKIP_DATES.include?(date)
        p "#{date} skipped.(#{PAGE})"
        LOG.info("#{date} skipped.(#{PAGE})")
        next
      end

      pageranks = Pagerank.new(date)
      pageranks.read
      
      urls_ids = Urls_id.new(date)
      urls_ids.find(pageranks.values.size)

      print_variable({pageranks_size: pageranks.values.size, urls_ids_size: urls_ids.values.size})

      @pageranks_days.push(pageranks)
      @urls_ids_days.push(urls_ids)

      print_line
    end
  end
end
