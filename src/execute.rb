require File.expand_path(File.dirname(__FILE__)) + '/new/common'
require File.expand_path(File.dirname(__FILE__)) + '/new/pagerank'
require File.expand_path(File.dirname(__FILE__)) + '/new/rankprestige'
require File.expand_path(File.dirname(__FILE__)) + '/new/urls_id'
require File.expand_path(File.dirname(__FILE__)) + '/new/urls_id_rp'
require File.expand_path(File.dirname(__FILE__)) + '/more_inc_ids'
require File.expand_path(File.dirname(__FILE__)) + '/calc_score_page_ps'
require File.expand_path(File.dirname(__FILE__)) + '/check_pk'
require File.expand_path(File.dirname(__FILE__)) + '/check_apk'

class Execute
  include Common

  def initialize(target: 'pagerank')
    p "target: #{target}"
    @target = target

    create_ranks_and_urls_ids_days
  end

  def run
    mo = MoreIncIds.new(@ranks_days, @urls_ids_days, target: @target)
    mo.run

    ca = CalcScorePagePs.new(@ranks_days, @urls_ids_days, target: @target)
    ca.run

    cpk = CheckPk.new(@ranks_days, @urls_ids_days, target: @target)
    cpk.run

    capk = CheckApk.new(target: @target)
    capk.run
  end

  private

  def create_ranks_and_urls_ids_days
    ### 各日のranksとurls_idsを紐付ける
    @ranks_days = []
    @urls_ids_days = []

    START_DATE.upto(END_DATE) do |date|
      print_dateline(date)

      if SKIP_DATES.include?(date)
        p "#{date} skipped.(#{PAGE})"
        LOG.info("#{date} skipped.(#{PAGE})")
        next
      end

      ranks = (@target == 'pagerank') ? Pagerank.new(date) : Rankprestige.new(date)
      ranks.read

      urls_ids = (@target == 'pagerank') ? UrlsId.new(date) : UrlsIdRp.new(date)
      # urls_ids = UrlsIdRp.new(date)
      urls_ids.find(ranks.values.size)

      print_variable(ranks_size: ranks.values.size, urls_ids_size: urls_ids.values.size)

      @ranks_days.push(ranks)
      @urls_ids_days.push(urls_ids)

      print_line
    end
  end
end
