require File.expand_path(File.dirname(__FILE__)) + '/new/common'
require File.expand_path(File.dirname(__FILE__)) + '/new/pagerank'
require File.expand_path(File.dirname(__FILE__)) + '/new/rankprestige'
require File.expand_path(File.dirname(__FILE__)) + '/new/urls_id'
require File.expand_path(File.dirname(__FILE__)) + '/new/urls_id_rp'

class MoreIncIds
  include Common

  attr_reader :urls_ids_days

  def initialize(ranks_days, urls_ids_days, target: 'pagerank')
    p "**** more_inc_ids.rb ****"
    LOG.info("**** more_inc_ids.rb ****")
    p "target: #{target}"
    LOG.info("target: #{target}")
    @target = target

    @ranks_days = ranks_days
    @urls_ids_days = urls_ids_days
  end

  def run
    terms = [1]

    TH_MORE_INCS.each do |th_more_inc|

      page_ps_urls_ids = []
      page_ps_date = []

      terms.each do |term|
        p "term: #{term}"
        LOG.info("term: #{term}")
        p "th_more_inc: #{th_more_inc}"
        LOG.info("th_more_inc: #{th_more_inc}")

        # 調べる期間の初日と最終日を設定
        start_term = START_DATE
        end_term = start_term + A_DATE - 1

        while end_term < (START_DATE + A_DATE)
          p "start_term: #{start_term}"
          LOG.info("start_term: #{start_term}")
          p "end_term: #{end_term}"
          LOG.info("end_term: #{end_term}")

          # 変化前と変化後のrank, urls_idを取得
          before_ranks = @ranks_days[start_term - START_DATE].values
          after_ranks = @ranks_days[end_term - START_DATE].values

          before_urls_ids = @urls_ids_days[start_term - START_DATE].values
          after_urls_ids = @urls_ids_days[end_term - START_DATE].values

          ### urls_idsを1つずつ調べていく
          before_urls_ids.each do |urls_id|
            # afterに含まれない場合は飛ばす
            next unless after_urls_ids.include?(urls_id)

            # それぞれ比較して、条件に適合するurls_idを適合urls_idsにpush
            pr_before = before_ranks[before_urls_ids.index(urls_id)]
            pr_after = after_ranks[after_urls_ids.index(urls_id)]

            #if ((pr_after.to_f / pr_before.to_f) >= th_more_inc.to_f)
            # 上昇と認める閾値(平均の2倍)
            term_urls_ids_size = after_urls_ids.size
            limit_more_inc = (1.0 / term_urls_ids_size) * th_more_inc.to_f

            # 単純に上がったらok
            # limit_more_inc = 0

            if (pr_after.to_f - pr_before.to_f) >= limit_more_inc
            # if (pr_after.to_f - pr_before.to_f) > limit_more_inc
              if page_ps_urls_ids.include?(urls_id)
                if page_ps_date[page_ps_urls_ids.index(urls_id)] > (start_term - START_DATE).to_i
                  # もっと手前の日付で見つかったらそちらを採用
                  page_ps_date[page_ps_urls_ids.index(urls_id)] = (start_term - START_DATE).to_i
                end
              else
                page_ps_urls_ids.push(urls_id)
                page_ps_date.push((start_term - START_DATE).to_i)
              end
            end
          end

          start_term += 1
          end_term += 1
        end
      end # terms

      result_file_name = "#{RESULTFILE_DIR}page_ps/#{@target}_a#{A_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}.csv"

      p "page_ps_urls_ids.size: #{page_ps_urls_ids.size}"
      LOG.info("page_ps_urls_ids.size: #{page_ps_urls_ids.size}")
      p "page_ps_date.size: #{page_ps_date.size}"
      LOG.info("page_ps_date.size: #{page_ps_date.size}")

      File.open(result_file_name, 'w') do |result_file|
        page_ps_urls_ids.each { |page_p_urls_id| result_file.write("#{page_p_urls_id},") }
        result_file.write("\n")
        page_ps_date.each { |page_p_date| result_file.write("#{page_p_date},") }
      end

      p "#{result_file_name} writed."
      LOG.info("#{result_file_name} writed.")

    end # TH_MORE_INCS
  end
end
