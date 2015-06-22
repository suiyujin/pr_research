require File.expand_path(File.dirname(__FILE__)) + '/common'

class Urls_id
  include Common

  attr_reader :values

  def initialize(date)
    @date = date
  end

  def find(size)
    # 1.upto(size) do |admin_id|
    #   count += 1
    #   urls_ids.push(select_urlsid_from_adminid(admin_id))
    # end
    @values = (1..size).to_a.map { |admin_id| select_urlsid_from_adminid(admin_id) }
  end

  private
  def select_urlsid_from_adminid(admin_id)
    MY.query("SELECT urls_id
      FROM urls_hash_#{@date.strftime("%Y%m%d")}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_id
      WHERE admin_id = #{admin_id};").fetch_row[0]
  end
end
