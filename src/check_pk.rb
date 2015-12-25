require File.expand_path(File.dirname(__FILE__)) + '/new/common'
require File.expand_path(File.dirname(__FILE__)) + '/new/pagerank'
require File.expand_path(File.dirname(__FILE__)) + '/new/rankprestige'
require File.expand_path(File.dirname(__FILE__)) + '/new/urls_id'
require File.expand_path(File.dirname(__FILE__)) + '/new/urls_id_rp'

class CheckPk
  include Common

  def initialize(ranks_days, urls_ids_days, target: 'pagerank')
    print_file_name

    @ranks_days = ranks_days
    @urls_ids_days = urls_ids_days

    p "target: #{target}"
    @target = target
  end

  def run
    # 正解条件
    # sudipr_uppr or sudipr or uppr or nodopr or 21_above

    TH_MORE_INCS.each do |th_more_inc|
      # page_ps_scoreファイルからurls_idとscoreを読み込む
      # page_ps_score: 予測スコアの高い順に並んでいる
      if TAIL_OF_FILE == '_penaltyq'
        read_file_name = "#{RESULTFILE_DIR}page_ps_score_2/#{@target}_score_a#{A_DATE}_b#{B_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime('%Y%m%d')}to#{END_DATE.strftime('%Y%m%d')}_#{REDUCE_WEIGHT.to_i}reduce_#{LIMIT_DESC_RATE.to_i}desc#{TAIL_OF_FILE}.csv"
      else
        read_file_name = "#{RESULTFILE_DIR}page_ps_score_2/#{@target}_score_a#{A_DATE}_b#{B_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime('%Y%m%d')}to#{END_DATE.strftime('%Y%m%d')}_#{REDUCE_WEIGHT.to_i}reduce#{TAIL_OF_FILE}.csv"
      end

      check_urls_ids = Array.new
      check_urls_scores = Array.new

      File.open(read_file_name, 'r') do |read_file|
        urls_ids_str, score_str = read_file.readlines
        check_urls_ids = urls_ids_str.chomp.split(',')
        check_urls_scores = score_str.chomp.split(',')
      end

      p "#{read_file_name} read."
      LOG.info("#{read_file_name} read.")

      p "check_urls_ids.size: #{check_urls_ids.size}"
      LOG.info("check_urls_ids.size: #{check_urls_ids.size}")
      p "check_urls_scores.size: #{check_urls_scores.size}"
      LOG.info("check_urls_scores.size: #{check_urls_scores.size}")

      ### 適合率を調べる
      ### (条件を切り替えられるようにする)

      # 最終的な結果を格納するための配列
      result_urls_ids = Array.new
      result_check = Array.new

      check_urls_ids.each do |check_urls_id|
        # 残りの全日程に結果が含まれているページのみ調べる
        if check_include_all_date?(check_urls_id)
          result_urls_ids << check_urls_id

          # 条件に適合した場合は1, 適合しなかった場合は0を結果とする
          if CHECK_FLAG == '21_above'
            result_check << (check_21_above_max_before7?(check_urls_id) ? 1 : 0)
          elsif CHECK_FLAG == '15to21_above'
            result_check << (check_15to21_above_max_before7?(check_urls_id) ? 1 : 0)
          elsif CHECK_FLAG == 'sudipr_uppr'
            if check_sum_diff_ranks?(check_urls_id) && check_up_rank?(check_urls_id)
              result_check << 1
            else
              result_check << 0
            end
          elsif CHECK_FLAG == 'sudipr'
            result_check << (check_sum_diff_ranks?(check_urls_id) ? 1 : 0)
          elsif CHECK_FLAG == 'uppr'
            result_check << (check_up_rank?(check_urls_id) ? 1 : 0)
          elsif CHECK_FLAG == 'nodopr'
            result_check << (check_not_down_rank?(check_urls_id) ? 1 : 0)
          end

        end
      end

      # ファイルに書き出す
      if TAIL_OF_FILE == '_penaltyq'
        result_file_name = "#{RESULTFILE_DIR}check_pk/#{@target}_a#{A_DATE}_b#{B_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_#{CHECK_FLAG}_#{REDUCE_WEIGHT.to_i}reduce_#{LIMIT_DESC_RATE.to_i}desc_#{LIMIT_DOWN_RATE.to_i}#{TAIL_OF_FILE}.csv"
      else
        result_file_name = "#{RESULTFILE_DIR}check_pk/#{@target}_a#{A_DATE}_b#{B_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_#{CHECK_FLAG}_#{REDUCE_WEIGHT.to_i}reduce_#{LIMIT_DOWN_RATE.to_i}#{TAIL_OF_FILE}.csv"
      end

      File.open(result_file_name, 'w') do |result_file|
        result_file.write("#{result_urls_ids.join(',')}\n")
        result_file.write(result_check.join(','))
      end

      p "#{result_file_name} writed."
      LOG.info("#{result_file_name} writed.")

    end # th_more_incs

  end

  def check_include_all_date?(urls_id)
    # 残りの全日程(8~21日)に結果が含まれているか調べる
    # 含まれていれば真、欠けていれば偽を返す
    include_flag = true
    (START_DATE + 7).upto(END_DATE) do |date|
      unless @urls_ids_days[date - START_DATE].values.include?(urls_id)
        include_flag = false
        break
      end
    end

    include_flag
  end

  def check_15to21_above_max_before7?(urls_id)
    # 15〜21日目の平均Rankが7日目までの最大Rankから閾値を超えて下がっていなければ正解

    # 7日目までの最大PRを調べる
    max_rank = 0.0

    (START_DATE).upto(START_DATE + 6) do |date|
      index_urls_id = @urls_ids_days[date - START_DATE].values.find_index(urls_id)
      date_rank = @ranks_days[date - START_DATE].values[index_urls_id].to_f

      max_rank = (max_rank < date_rank) ? date_rank : max_rank
    end

    # 15〜21日目の平均Rankが閾値以上下降していなければ正解
    last_ave_rank = 0.0
    END_DATE.downto(END_DATE - 6) do |date|
      index_urls_id = @urls_ids_days[date - START_DATE].values.find_index(urls_id)
      last_ave_rank += @ranks_days[date - START_DATE].values[index_urls_id].to_f
    end
    last_ave_rank /= 7.0

    # 閾値：1/【最終日の総ページ数】
    #threshold = (1.0 / @urls_ids_days.last.values.size.to_f)

    #((max_rank - threshold) <= last_rank) ? true : false
    (last_ave_rank >= (max_rank * (LIMIT_DOWN_RATE.to_f / 100.0))) ? true : false
  end

  def check_21_above_max_before7?(urls_id)
    # 21日目のRankが7日目までの最大Rankから閾値を超えて下がっていなければ正解
    # 最大値より20%値を下げていなければ正解に変更

    # 7日目までの最大PRを調べる
    max_rank = 0.0

    (START_DATE).upto(START_DATE + 6) do |date|
      index_urls_id = @urls_ids_days[date - START_DATE].values.find_index(urls_id)
      date_rank = @ranks_days[date - START_DATE].values[index_urls_id].to_f

      max_rank = (max_rank < date_rank) ? date_rank : max_rank
    end

    # 21日目が閾値以上下降していなければ正解
    index_urls_id_21 = @urls_ids_days.last.values.find_index(urls_id)
    last_rank = @ranks_days.last.values[index_urls_id_21].to_f

    # 閾値：1/【最終日の総ページ数】
    #threshold = (1.0 / @urls_ids_days.last.values.size.to_f)

    #((max_rank - threshold) <= last_rank) ? true : false
    (last_rank >= (max_rank * (LIMIT_DOWN_RATE.to_f / 100.0))) ? true : false
  end

  def check_sum_diff_ranks?(urls_id)
    # 7日目から21日目までのranksの差分の合計が誤差より上となっているか調べる
    # 結局7日目と21日目を比べているのと同じ
    # 正解なら真、不正解なら偽を返す

    sum_diff_ranks = 0.0

    # 初期値は7日目のRank
    index_urls_id = @urls_ids_days[6].values.find_index(urls_id)
    before_rank = @ranks_days[6].values[index_urls_id].to_f

    (START_DATE + 7).upto(END_DATE) do |date|
      # 当日のrankと前日の差分を調べる
      index_date_urls_id = @urls_ids_days[date - START_DATE].values.find_index(urls_id)
      date_rank = @ranks_days[date - START_DATE].values[index_date_urls_id].to_f

      diff_rank = date_rank - before_rank
      sum_diff_ranks += diff_rank

      before_rank = date_rank
    end

    # 1/【最終日の時系列Webグラフのノード数】分は誤差とする
    error_range = (1.0 / @ranks_days[END_DATE - START_DATE].values.size.to_f)

    #(sum_diff_ranks >= 0.0) ? true : false
    #誤差を認めるようにする
    ((sum_diff_ranks + error_range) >= 0) ? true : false
  end

  def check_not_down_rank?(urls_id)
    # 8日目以降に7日目のRankから指定以上下がらなければ正解
    # 正解なら真、不正解なら偽を返す
    not_down_flag = true

    # 7日目のRank
    index_urls_id = @urls_ids_days[6].values.find_index(urls_id)
    before_rank = @ranks_days[6].values[index_urls_id].to_f

    # 2割以上下がれば不正解！
    limit_rank = before_rank * 0.7

    (START_DATE + 7).upto(END_DATE) do |date|
      # 1/【その日の時系列Webグラフのノード数】以上下がれば不正解！
      #limit_rank = before_rank - (1.0 / @ranks_days[date - START_DATE].values.size.to_f)

      # 当日のrankと7日目のRankの差分を調べる
      index_date_urls_id = @urls_ids_days[date - START_DATE].values.find_index(urls_id)
      date_rank = @ranks_days[date - START_DATE].values[index_date_urls_id].to_f

      if date_rank < limit_rank
        not_down_flag = false
        break
      end
    end

    not_down_flag
  end

  def check_up_rank?(urls_id)
    # 8日目以降に7日目のRankから指定以上上がれば正解
    # 正解なら真、不正解なら偽を返す
    up_flag = false

    # 7日目のRank
    index_urls_id = @urls_ids_days[6].values.find_index(urls_id)
    before_rank = @ranks_days[6].values[index_urls_id].to_f

    (START_DATE + 7).upto(END_DATE) do |date|
      # 1/【その日の時系列Webグラフのノード数】以上上がれば正解！
      limit_rank = before_rank + (1.0 / @ranks_days[date - START_DATE].values.size.to_f)

      # 当日のrankと7日目のRankの差分を調べる
      index_date_urls_id = @urls_ids_days[date - START_DATE].values.find_index(urls_id)
      date_rank = @ranks_days[date - START_DATE].values[index_date_urls_id].to_f

      if date_rank >= limit_rank
        up_flag = true
        break
      end
    end

    up_flag
  end

  def check_inlinks?
    # inlinksが__となっているか調べる
    # 正解なら真、不正解なら偽を返す
  end

  def check_centrality?
    # 中心度が__となっているか調べる
    # 正解なら真、不正解なら偽を返す
  end

  def print_file_name
    p "**** #{File.basename(__FILE__)} ****"
    LOG.info("**** #{File.basename(__FILE__)} ****")
  end
end
