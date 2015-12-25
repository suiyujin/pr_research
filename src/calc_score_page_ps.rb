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

    @all_pages = []
    @all_page_qs = []
  end

  def run
    TH_MORE_INCS.each do |th_more_inc|
      # Rを読み込んでインスタンス生成
      page_ps = read_page_ps(th_more_inc)

      if TAIL_OF_FILE == '_withq'
        # all_pagesにマージ
        @all_pages |= page_ps

        # Rから観測全日程のQを生成して出リンク先を調べておく
        ready_page_qs(page_ps)
        find_outlink_pages_from_page_qs(page_ps)
      elsif TAIL_OF_FILE == '_penaltyq'
        # all_pagesにマージ
        @all_pages |= page_ps

        # Rから観測全日程のQを生成して出リンク先を調べておく
        ready_page_qs(page_ps)
        find_outlink_pages_from_page_qs(page_ps)

        penalty_page_qs = calc_penalty_page_qs(page_ps, th_more_inc)
      end

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
          urls_id_index_date2 = @urls_ids_days[1].values.find_index do |urls_id_by_date|
            urls_id_by_date == page_p.urls_id
          end

          # Rがその日にクロールされていない場合はスコア0とする(次のRへ進む)
          next if urls_id_index.nil?

          if TAIL_OF_FILE == '_withq'
            # Qのスコアを加算
            page_qs = page_p.inlink_pages_by_date[date - START_DATE]
            if page_qs
              page_qs_score = page_qs.inject(0.0) do |sum, page_q|
                sum += page_q.score_qs_by_date(date, page_ps)
              end
              page_p.score_r += page_qs_score
            end
          elsif TAIL_OF_FILE == '_penaltyq'
            # ペナルティのQからリンクされていたRを取り除く
            count = penalty_page_qs.count do |page_q|
              page_q.outlink_pages_by_date[1].include?(page_p)
            end
            if count >= 1
              next
            end
          end

          # 当日のrankと2日日のrankを調べる
          before_pr = @ranks_days[1].values[urls_id_index_date2].to_f
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

  def calc_penalty_page_qs(page_ps, th_more_inc)
    penalty_page_qs = []
    # Qの出リンク先のページがその後どのように変動するか調査する

    # checked_pages = []
    # 2日目を基準とする
    date = START_DATE + A_DATE - 1
    p "date: #{date}"
    LOG.info("date: #{date}")

    all_page_qs_status = @all_page_qs.map do |page_q|
      # (START_DATE + A_DATE).upto(START_DATE + B_DATE - 1) do |date|

      date_index = date - START_DATE

      page_qs_status = page_q.outlink_pages_by_date[date_index].map do |outlink_page|
        # 3日目から7日目まで調べる
        start_term = START_DATE + A_DATE
        end_term = START_DATE + B_DATE - 1
        desc_page?(start_term, end_term, outlink_page, th_more_inc)
      end

      # 指定割合以上下降しているQを調べる
      # 指定割合以上下降していればtrueを返す
      desc_page_rate = (page_qs_status.count(true).to_f / page_qs_status.size.to_f) * 100.0
      (desc_page_rate >= LIMIT_DESC_RATE)
    end

    # 結果を出力
    p "all_page_qs size: #{@all_page_qs.size}"
    p "all_page_qs_status size: #{all_page_qs_status.size}"
    p "all_page_qs desc size: #{all_page_qs_status.count(true)}"
    p "all_page_qs not desc size: #{all_page_qs_status.count(false)}"
    LOG.info("all_page_qs size: #{@all_page_qs.size}")
    LOG.info("all_page_qs size: #{all_page_qs_status.size}")
    LOG.info("all_page_qs desc size: #{all_page_qs_status.count(true)}")
    LOG.info("all_page_qs not desc size: #{all_page_qs_status.count(false)}")

    # TODO: 下降しているQからリンクされていたページRのスコアにペナルティを与える
    penalty_page_qs |= @all_page_qs.select.with_index do |_, i|
      all_page_qs_status[i]
    end

    penalty_page_qs
  end

  def desc_page?(start_term, end_term, page, th_more_inc)
    # デフォルトの最大値は2日目のPR
    max_rank = @ranks_days[A_DATE - 1].values[@urls_ids_days[A_DATE - 1].values.index(page.urls_id)].to_f

    start_term.upto(end_term) do |term|
      # rank, urls_idを取得
      ranks = @ranks_days[term - START_DATE].values
      urls_ids = @urls_ids_days[term - START_DATE].values

      # 含まれない場合は飛ばす
      next unless urls_ids.include?(page.urls_id)

      rank = ranks[urls_ids.index(page.urls_id)]
      if rank.to_f > max_rank
        # それまでの最大値より大きければ、最大値を更新
        max_rank = rank.to_f
      else
        # 最大値より閾値を越えて下がっていればtrueを返す
        limit_more_desc = (1.0 / urls_ids.size.to_f) * th_more_inc.to_f
        return true if (max_rank - rank.to_f) >= limit_more_desc
      end
    end

    false
  end

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

  def ready_page_qs(page_ps)
    if TAIL_OF_FILE == '_penaltyq'
      st_date = en_date = START_DATE + A_DATE - 1
    else
      st_date = START_DATE
      en_date = START_DATE + B_DATE - 1
    end

    st_date.upto(en_date) do |date|
      p "---#{date.to_s}---"
      date_index = date - START_DATE

      # page_pのinlink_pages_by_date(つまりqの集合)を作る
      page_ps.each do |page_p|
        if page_p.inlink_urls_ids_by_date[date_index]
          page_p.inlink_pages_by_date[date_index] = page_p.inlink_urls_ids_by_date[date_index].map do |inlink_urls_id|
            # @all_page_qsから探す
            page_q = search_all_page_qs(inlink_urls_id)
            unless page_q
              # 含まれていなければ、page_psから探す
              page_q = search_page_ps(page_ps, inlink_urls_id)
              unless page_q
                # どちらにも含まれていなければ、新しくインスタンスを生成
                page_q = Page.new(urls_id: inlink_urls_id)
              end
              @all_page_qs << page_q
            end
            page_q
          end
        end
      end

      # all_pagesにマージ
      @all_pages |= @all_page_qs
    end

    p "ready page qs."
    LOG.info("ready page qs.")
  end

  def find_outlink_pages_from_page_qs(page_ps)
    if TAIL_OF_FILE == '_penaltyq'
      st_date = en_date = START_DATE + A_DATE - 1
    else
      st_date = START_DATE
      en_date = START_DATE + B_DATE - 1
    end

    st_date.upto(en_date) do |date|
      p "---#{date.to_s}---"
      date_index = date - START_DATE

      # page_qのoutlink_pages_by_dateを作る
      @all_page_qs.each do |all_page_q|
        unless all_page_q.outlink_urls_ids_by_date[date_index]
          all_page_q.outlink_pages_by_date[date_index] = nil
          next
        end

        all_page_q.outlink_pages_by_date[date_index] = all_page_q.outlink_urls_ids_by_date[date_index].map do |outlink_urls_id|
          # @all_pagesから探す
          outlink_page = search_all_pages(outlink_urls_id)
          unless outlink_page
            # 含まれていなければ、新しくインスタンスを生成
            outlink_page = Page.new(urls_id: outlink_urls_id)
            # all_pagesに追加
            @all_pages << outlink_page
          end
          outlink_page
        end
        # page_qのスコアを計算する
        # all_page_q.calc_score_qs_by_date(date, page_ps)
      end
    end
    p "find outlink pages form page_qs."
    LOG.info("find outlink pages form page_qs.")
  end

  # @all_pagesを探す
  # 含まれていなければnilを返す
  def search_all_pages(urls_id)
    all_pages_index = @all_pages.index do |all_page|
      all_page.urls_id == urls_id
    end
    all_pages_index ? @all_pages[all_pages_index] : nil
  end

  # @all_page_qsを探す
  # 含まれていなければnilを返す
  def search_all_page_qs(urls_id)
    all_page_qs_index = @all_page_qs.index do |all_page_q|
      all_page_q.urls_id == urls_id
    end
    all_page_qs_index ? @all_page_qs[all_page_qs_index] : nil
  end

  # page_psを探す
  # 含まれていなければnilを返す
  def search_page_ps(page_ps, urls_id)
    page_ps_index = page_ps.index do |page_p|
      page_p.urls_id == urls_id
    end
    page_ps_index ? page_ps[page_ps_index] : nil
  end

  def create_csv(page_ps_sort_by_score_r, th_more_inc)
    # 書き込み用配列を用意
    urls_ids = page_ps_sort_by_score_r.map(&:urls_id)
    score_rs = page_ps_sort_by_score_r.map(&:score_r)

    if TAIL_OF_FILE == '_penaltyq'
      write_file_path = "#{RESULTFILE_DIR}page_ps_score_2/#{@target}_score_a#{A_DATE}_b#{B_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_#{REDUCE_WEIGHT.to_i}reduce_#{LIMIT_DESC_RATE.to_i}desc#{TAIL_OF_FILE}.csv"
    else
      write_file_path = "#{RESULTFILE_DIR}page_ps_score_2/#{@target}_score_a#{A_DATE}_b#{B_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_#{REDUCE_WEIGHT.to_i}reduce#{TAIL_OF_FILE}.csv"
    end

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
