require File.expand_path(File.dirname(__FILE__)) + '/common'

class Page
  include Common

  attr_accessor :score_r, :bonus_score_r, :inlink_pages_by_date, :outlink_pages_by_date
  attr_reader :urls_id, :admin_ids_by_date, :score_qs_by_date, :inlink_urls_ids_by_date, :outlink_urls_ids_by_date

  def initialize(urls_id:)
    @urls_id = urls_id
    @score_r = 0.0
    @bonus_score_r = 0.0
    set_admin_ids_by_date

    @score_qs_by_date = []

    @inlink_pages_by_date = []
    @outlink_pages_by_date = []
  end

  def inlink_urls_ids_by_date
    @inlink_urls_ids_by_date ||= (START_DATE..(START_DATE + B_DATE - 1)).to_a.map do |date|
      admin_id = @admin_ids_by_date[date - START_DATE]
      if admin_id
        base_ids = getbaseids_from_outid(date, admin_id)
        if base_ids
          inlink_urls_ids = base_ids.map do |base_id|
            geturlsid_from_adminid(date, base_id)
          end
        else
          inlink_urls_ids = nil
        end
      else
        inlink_urls_ids = nil
      end
      inlink_urls_ids
    end
  end

  def outlink_urls_ids_by_date
    @outlink_urls_ids_by_date ||= (START_DATE..(START_DATE + B_DATE - 1)).to_a.map do |date|
      admin_id = @admin_ids_by_date[date - START_DATE]
      if admin_id
        out_ids = getoutids_from_baseid(date, admin_id)
        outlink_urls_ids = out_ids.map do |out_id|
          geturlsid_from_adminid(date, out_id)
        end
      else
        outlink_urls_ids = nil
      end
      outlink_urls_ids
    end
  end

  def score_qs_by_date(date, page_rs)
    return @score_qs_by_date[date - START_DATE] if @score_qs_by_date[date - START_DATE]
    # Qのその日のoutlinkの内、Rの割合をその日のスコアとする
    outlink_pages = @outlink_pages_by_date[date - START_DATE]
    if outlink_pages
      score_qs = (outlink_pages & page_rs).size.to_f / outlink_pages.size.to_f
    else
      score_qs = 0.0
    end
    @score_qs_by_date[date - START_DATE] = score_qs
  end

  def calc_score_qs_by_date(date, page_rs)
    # Qのその日のoutlinkの内、Rの割合をその日のスコアとする
    outlink_pages = @outlink_pages_by_date[date - START_DATE]
    @score_qs_by_date[date - START_DATE] = (outlink_pages & page_rs).size.to_f / outlink_pages.size.to_f
  end

  private

  def set_admin_ids_by_date
    @admin_ids_by_date = (START_DATE..(START_DATE + B_DATE - 1)).to_a.map do |date|
      getadminid_from_urlsid(date)
    end
  end

  def getadminid_from_urlsid(date)
    result = MY.query("SELECT admin_id
      FROM urls_hash_#{date.strftime("%Y%m%d")}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_id
      WHERE urls_id = #{@urls_id};")
    result.num_rows == 0 ? nil : result.fetch_row[0]
  end

  def geturlsid_from_adminid(date, admin_id)
    result = MY.query("SELECT urls_id
      FROM urls_hash_#{date.strftime("%Y%m%d")}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_id
      WHERE admin_id = #{admin_id};")
    result.num_rows == 0 ? nil : result.fetch_row[0]
  end

  def getbaseids_from_outid(date, out_id)
    result = MY.query("SELECT base_id
      FROM result_#{date.strftime("%Y%m%d")}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}
      WHERE out_id = #{out_id};")
    result.num_rows == 0 ? nil : result.to_a.flatten
  end

  def getoutids_from_baseid(date, base_id)
    result = MY.query("SELECT out_id
      FROM result_#{date.strftime("%Y%m%d")}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}
      WHERE base_id = #{base_id};")
    result.num_rows == 0 ? nil : result.to_a.flatten
  end
end
