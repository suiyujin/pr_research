require 'csv'
require File.expand_path(File.dirname(__FILE__)) + '/new/common'
require File.expand_path(File.dirname(__FILE__)) + '/new/pagerank'
require File.expand_path(File.dirname(__FILE__)) + '/new/urls_id'

class Create_timeinlinks_csv
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

    # 指定されたurls_idのinlinks数を日付ごとに格納する
    START_DATE.upto(END_DATE) do |date|
      inlinks_num = 0
      
      admin_id = getadminid_from_urlsid(date, create_urls_id)
      unless admin_id.nil?
        inlinks = getbaseid_from_outid(date, admin_id)
        inlinks_num = inlinks.size unless inlinks.nil?
      end

      result_csv.push([inlinks_num])
    end
    
    write_file_name = "timeinlinks_#{PAGE}_from#{START_DATE.yday}to#{END_DATE.yday}_#{create_urls_id}.txt"

    CSV.open("#{RESULTFILE_DIR}timeinlinks/#{write_file_name}", 'w') do |write_file|
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

  def getbaseid_from_outid(date, out_id)
    result = MY.query("SELECT base_id
      FROM result_#{date.strftime("%Y%m%d")}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}
      WHERE out_id = #{out_id};")
    return result.num_rows == 0 ? nil : result.to_a.flatten
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
