require File.expand_path(File.dirname(__FILE__)) + '/common'

class UrlsIdRp
  include Common

  attr_reader :values

  def initialize(date)
    @date = date

    relative_file_name = "relative_id_#{date.strftime('%Y%m%d')}_limit#{LIMIT_SEEDS_NUM}.txt"
    @date_ids = []
    @admin_ids = []
    File.open("#{RESULT_MAXFLOW_DIR}#{relative_file_name}", 'r') do |relative_file|
      readlines = relative_file.readlines
      @date_ids = readlines[0].chomp.split(',')
      @admin_ids = readlines[1].chomp.split(',')
    end
  end

  def find(size)
    # @admin_idsからdate_idsを作る
    date_ids = @admin_ids.map do |admin_id|
      @date_ids[admin_id.to_i - 1]
    end

    # date_idsからurl_hashesを作る
    url_hashes = select_url_hashes_from_dateids(date_ids)

    # url_hashesから@valuesを作る
    @values = select_ids_from_url_hashes(url_hashes)
  end

  private

  def select_url_hashes_from_dateids(date_ids)
    date_ids_str = "#{date_ids.join(',')}"
    MY.query("SELECT url_hash
      FROM url_hash_#{@date.strftime("%Y%m%d")}
      WHERE id in (#{date_ids_str});").to_a.flatten
  end

  def select_ids_from_url_hashes(url_hashes)
    url_hashes_str = "'#{url_hashes.join("','")}'"
    MY.query("SELECT id
      FROM (
        SELECT min(id) AS id, url_hash
        FROM urls
        GROUP BY url_hash
      ) AS distinct_urls
      WHERE url_hash in (#{url_hashes_str});").to_a.flatten
  end
end
