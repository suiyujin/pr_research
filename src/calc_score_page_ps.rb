require File.expand_path(File.dirname(__FILE__)) + '/new/common'
require File.expand_path(File.dirname(__FILE__)) + '/new/page'
require File.expand_path(File.dirname(__FILE__)) + '/new/rankprestige'
require File.expand_path(File.dirname(__FILE__)) + '/new/pagerank'
require File.expand_path(File.dirname(__FILE__)) + '/new/urls_id'
require File.expand_path(File.dirname(__FILE__)) + '/new/urls_id_rp'

class CalcScorePagePs
  include Common

  def initialize(ranks_days, urls_ids_days, target: 'pagerank')
    print_file_name
    p "target: #{target}"

    @ranks_days = ranks_days
    @urls_ids_days = urls_ids_days

    @target = target
  end

  def run
    TH_MORE_INCS.each do |th_more_inc|
      # Rを読み込んでインスタンス生成
      page_ps = read_page_ps(th_more_inc)

      ### 3日目から7日目までスコアリングする
      (START_DATE + A_DATE).upto(START_DATE + B_DATE - 1) do |date|
        p "date: #{date}"
        LOG.info("date: #{date}")

        # Rごとに調べる
        page_ps.each do |page_p|
          # urls_idのindexを調べる
          urls_id_index = @urls_ids_days[date - START_DATE].values.find_index do |urls_id_by_date|
            urls_id_by_date == page_p.urls_id
          end

          # Rがその日にクロールされていない場合はスコア0とする(次のRへ進む)
          next if urls_id_index.nil?

          # 当日のrankと2日日のrankを調べる
          before_pr = @ranks_days[1].values[urls_id_index].to_f
          after_pr = @ranks_days[date - START_DATE].values[urls_id_index].to_f

          ### 比較して結果に応じてスコアリング
          diff_pr = after_pr - before_pr

          # page_p.score_r += (diff_pr / before_pr)

          # 正の場合：上昇率を加算
          # 負の場合：下降率を減算
          if diff_pr >= 0
            percentage_raise = (diff_pr / before_pr)
            page_p.score_r += percentage_raise
#
#            # さらに上がり続けている場合はボーナスも加える
#            # (上がり続けている分全て足す)
#            page_p.score_r += page_p.bonus_score_r
#            # 次のためにボーナスを増やす
#            page_p.bonus_score_r += percentage_raise
          else
            page_p.score_r += (diff_pr / before_pr) * REDUCE_WEIGHT
#
#            # 次のボーナスを0にする
#            page_p.bonus_score_r = 0.0
          end
        end
      end # date

      # Rをスコアが高い順にファイルへ書き込む
      # urls_idとscore_r
      page_ps_sort_by_score_r = page_ps.sort_by(&:score_r).reverse

      create_csv(page_ps_sort_by_score_r, th_more_inc)
    end # th_more_incs
  end

  private

  def read_page_ps(th_more_inc)
    read_file_name = "#{RESULTFILE_DIR}page_ps/#{@target}_a#{A_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime('%Y%m%d')}to#{END_DATE.strftime('%Y%m%d')}.csv"

    page_ps_urls_ids = []
    page_ps_date = []

    File.open(read_file_name, 'r') do |read_file|
      page_ps_urls_ids_str, page_ps_date_str = read_file.readlines
      page_ps_urls_ids = page_ps_urls_ids_str.chomp.split(',')
      page_ps_date = page_ps_date_str.chomp.split(',')
    end

    p "#{read_file_name} read."
    LOG.info("#{read_file_name} read.")

    p "page_ps_urls_ids.size: #{page_ps_urls_ids.size}"
    LOG.info("page_ps_urls_ids.size: #{page_ps_urls_ids.size}")
    p "page_ps_date.size: #{page_ps_date.size}"
    LOG.info("page_ps_date.size: #{page_ps_date.size}")

    page_ps = page_ps_urls_ids.map do |page_ps_urls_id|
      Page.new(urls_id: page_ps_urls_id)
    end

    # 全日程に結果が含まれているページのみに絞る
    page_ps.select! { |page_p| check_include_all_date?(page_p.urls_id) }

    page_ps
  end

  def create_csv(page_ps_sort_by_score_r, th_more_inc)
    # 書き込み用配列を用意
    urls_ids = page_ps_sort_by_score_r.map(&:urls_id)
    score_rs = page_ps_sort_by_score_r.map(&:score_r)

    write_file_path = "#{RESULTFILE_DIR}page_ps_score_2/#{@target}_score_a#{A_DATE}_b#{B_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_#{REDUCE_WEIGHT.to_i}reduce#{TAIL_OF_FILE}.csv"

    File.open(write_file_path, 'w') do |write_file|
      urls_ids.each { |urls_id| write_file.write("#{urls_id},") }
      write_file.write("\n")
      score_rs.each { |score_r| write_file.write("#{score_r},") }
    end

    p "#{write_file_path} writed."
    LOG.info("#{write_file_path} writed.")
  end

  def check_include_all_date?(urls_id)
    # 全日程に結果が含まれているか調べる
    # 含まれていれば真、欠けていれば偽を返す
    include_flag = true
    (START_DATE).upto(END_DATE) do |date|
      unless @urls_ids_days[date - START_DATE].values.include?(urls_id)
        include_flag = false
        break
      end
    end

    include_flag
  end

  def print_file_name
    p "**** #{File.basename(__FILE__)} ****"
    LOG.info("**** #{File.basename(__FILE__)} ****")
  end
end
