require File.expand_path(File.dirname(__FILE__)) + '/new/common'
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
      # Rを読み込む
      # idとscoreのハッシュを用意する
      page_ps = read_page_ps(th_more_inc)

      ### 3日目から7日目までスコアリングする
      (START_DATE + A_DATE).upto(START_DATE + B_DATE - 1) do |date|
        p "date: #{date}"
        LOG.info("date: #{date}")

        # Rごとに調べる
        page_ps.each do |page_p|
          # urls_idのindexを調べる
          urls_id_index = @urls_ids_days[date - START_DATE].values.find_index do |urls_id_by_date|
            urls_id_by_date == page_p[:urls_id]
          end

          # Rがその日にクロールされていない場合はスコア0とする(次のRへ進む)
          next if urls_id_index.nil?

          # 当日のrankと2日日のrankを調べる
          before_pr = @ranks_days[1].values[urls_id_index].to_f
          after_pr = @ranks_days[date - START_DATE].values[urls_id_index].to_f

          ### 比較して結果に応じてスコアリング
          # 正の場合：上昇率を加算
          # 負の場合：下降率を減算
          diff_pr = after_pr - before_pr

          page_p[:score] += (diff_pr / before_pr)

#          if diff_pr >= 0
#            percentage_raise = (diff_pr / before_pr)
#            page_p[:score] += percentage_raise
#
#            # さらに上がり続けている場合はボーナスも加える
#            # (上がり続けている分全て足す)
#            page_p[:score] += page_p[:bonus_score]
#            # 次のためにボーナスを増やす
#            page_p[:bonus_score] += percentage_raise
#          else
#             page_p[:score] += (diff_pr / before_pr)
#
#            # 次のボーナスを0にする
#            page_p[:bonus_score] = 0.0
#          end
        end
      end # date

      # Rをスコアが高い順にファイルへ書き込む
      # urls_idとscore
      page_ps_sort_by_score = page_ps.sort_by { |page_p| page_p[:score] }.reverse

      create_csv(page_ps_sort_by_score, th_more_inc)
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

    page_ps = []
    page_ps_urls_ids.each_with_index do |page_ps_urls_id, index|
      page_ps.push(
        {
          urls_id: page_ps_urls_id,
          date: (START_DATE + page_ps_date[index].to_i),
          score: 0.0,
          bonus_score: 0.0
        }
      )
    end

    # 全日程に結果が含まれているページのみに絞る
    page_ps.select! { |page_p| check_include_all_date?(page_p[:urls_id]) }

    page_ps
  end

  def create_csv(page_ps_sort_by_score, th_more_inc)
    # 書き込み用配列を用意
    urls_ids, dates, scores = page_ps_sort_by_score.map(&:values).transpose

    write_file_path = "#{RESULTFILE_DIR}page_ps_score_2/#{@target}_score_a#{A_DATE}_b#{B_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_#{REDUCE_WEIGHT.to_i}reduce#{TAIL_OF_FILE}.csv"

    File.open(write_file_path, 'w') do |write_file|
      urls_ids.each { |urls_id| write_file.write("#{urls_id},") }
      write_file.write("\n")
      scores.each { |score| write_file.write("#{score},") }
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
