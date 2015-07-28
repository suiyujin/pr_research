require File.expand_path(File.dirname(__FILE__)) + '/new/common'
require File.expand_path(File.dirname(__FILE__)) + '/new/pagerank'
require File.expand_path(File.dirname(__FILE__)) + '/new/urls_id'

class CheckPk
  include Common

  def initialize
    print_file_name

    # PageRankとurls_idsを紐付けておく
    create_pageranks_and_urls_ids_days
  end

  def run
    # 正解条件を指定
    # sudipr_uppr or sudipr or uppr or nodopr or 21_above
    check_flag = '21_above'

    TH_MORE_INCS.each do |th_more_inc|
      # page_ps_scoreファイルからurls_idとscoreを読み込む
      # page_ps_score: 予測スコアの高い順に並んでいる
      read_file_name = "#{RESULTFILE_DIR}page_ps_score_2/score_n#{N_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime('%Y%m%d')}to#{END_DATE.strftime('%Y%m%d')}_#{REDUCE_WEIGHT.to_i}reduce#{TAIL_OF_FILE}.csv"

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
      log.info("check_urls_ids.size: #{check_urls_ids.size}")
      p "check_urls_scores.size: #{check_urls_scores.size}"
      log.info("check_urls_scores.size: #{check_urls_scores.size}")

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
          if check_flag == '21_above'
            result_check << (check_21_above_max_before7?(check_urls_id) ? 1 : 0)
          elsif check_flag == 'sudipr_uppr'
            if check_sum_diff_pageranks?(check_urls_id) && check_up_pagerank?(check_urls_id)
              result_check << 1
            else
              result_check << 0
            end
          elsif check_flag == 'sudipr'
            result_check << (check_sum_diff_pageranks?(check_urls_id) ? 1 : 0)
          elsif check_flag == 'uppr'
            result_check << (check_up_pagerank?(check_urls_id) ? 1 : 0)
          elsif check_flag == 'nodopr'
            result_check << (check_not_down_pagerank?(check_urls_id) ? 1 : 0)
          end

        end
      end
      
      # ファイルに書き出す
      result_file_name = "#{RESULTFILE_DIR}check_pk/n#{N_DATE}_#{th_more_inc}times_#{PAGE}_from#{START_DATE.strftime("%Y%m%d")}to#{END_DATE.strftime("%Y%m%d")}_#{check_flag}_#{REDUCE_WEIGHT.to_i}reduce#{TAIL_OF_FILE}_95.csv"

      File.open(result_file_name, 'w') do |result_file|
        result_file.write("#{result_urls_ids.join(',')}\n")
        result_file.write(result_check.join(','))
      end

      p "#{result_file_name} writed."
      log.info("#{result_file_name} writed.")

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
  
  def check_21_above_max_before7?(urls_id)
    # 21日目のPageRankが7日目までの最大PageRankから閾値を超えて下がっていなければ正解
    # 最大値より20%値を下げていなければ正解に変更

    # 7日目までの最大PRを調べる
    max_pagerank = 0.0

    (START_DATE).upto(START_DATE + 6) do |date|
      index_urls_id = @urls_ids_days[date - START_DATE].values.find_index(urls_id)
      date_pagerank = @pageranks_days[date - START_DATE].values[index_urls_id].to_f

      max_pagerank = (max_pagerank < date_pagerank) ? date_pagerank : max_pagerank
    end

    # 21日目が閾値以上下降していなければ正解
    index_urls_id_21 = @urls_ids_days.last.values.find_index(urls_id)
    last_pagerank = @pageranks_days.last.values[index_urls_id_21].to_f

    # 閾値：1/【最終日の総ページ数】
    #threshold = (1.0 / @urls_ids_days.last.values.size.to_f)

    #((max_pagerank - threshold) <= last_pagerank) ? true : false
    (last_pagerank >= (max_pagerank * 0.95)) ? true : false
  end

  def check_sum_diff_pageranks?(urls_id)
    # 7日目から21日目までのpageranksの差分の合計が誤差より上となっているか調べる
    # 結局7日目と21日目を比べているのと同じ
    # 正解なら真、不正解なら偽を返す

    sum_diff_pageranks = 0.0

    # 初期値は7日目のPageRank
    index_urls_id = @urls_ids_days[6].values.find_index(urls_id)
    before_pagerank = @pageranks_days[6].values[index_urls_id].to_f

    (START_DATE + 7).upto(END_DATE) do |date|
      # 当日のPagerankと前日の差分を調べる
      index_date_urls_id = @urls_ids_days[date - START_DATE].values.find_index(urls_id)
      date_pagerank = @pageranks_days[date - START_DATE].values[index_date_urls_id].to_f

      diff_pagerank = date_pagerank - before_pagerank
      sum_diff_pageranks += diff_pagerank

      before_pagerank = date_pagerank
    end
    
    # 1/【最終日の時系列Webグラフのノード数】分は誤差とする
    error_range = (1.0 / @pageranks_days[END_DATE - START_DATE].values.size.to_f)

    #(sum_diff_pageranks >= 0.0) ? true : false
    #誤差を認めるようにする
    ((sum_diff_pageranks + error_range) >= 0) ? true : false
  end

  def check_not_down_pagerank?(urls_id)
    # 8日目以降に7日目のPageRankから指定以上下がらなければ正解
    # 正解なら真、不正解なら偽を返す
    not_down_flag = true

    # 7日目のPageRank
    index_urls_id = @urls_ids_days[6].values.find_index(urls_id)
    before_pagerank = @pageranks_days[6].values[index_urls_id].to_f
    
    # 2割以上下がれば不正解！
    limit_pagerank = before_pagerank * 0.7

    (START_DATE + 7).upto(END_DATE) do |date|
      # 1/【その日の時系列Webグラフのノード数】以上下がれば不正解！
      #limit_pagerank = before_pagerank - (1.0 / @pageranks_days[date - START_DATE].values.size.to_f)

      # 当日のPagerankと7日目のPageRankの差分を調べる
      index_date_urls_id = @urls_ids_days[date - START_DATE].values.find_index(urls_id)
      date_pagerank = @pageranks_days[date - START_DATE].values[index_date_urls_id].to_f

      if date_pagerank < limit_pagerank
        not_down_flag = false
        break
      end
    end

    not_down_flag
  end

  def check_up_pagerank?(urls_id)
    # 8日目以降に7日目のPageRankから指定以上上がれば正解
    # 正解なら真、不正解なら偽を返す
    up_flag = false

    # 7日目のPageRank
    index_urls_id = @urls_ids_days[6].values.find_index(urls_id)
    before_pagerank = @pageranks_days[6].values[index_urls_id].to_f

    (START_DATE + 7).upto(END_DATE) do |date|
      # 1/【その日の時系列Webグラフのノード数】以上上がれば正解！
      limit_pagerank = before_pagerank + (1.0 / @pageranks_days[date - START_DATE].values.size.to_f)

      # 当日のPagerankと7日目のPageRankの差分を調べる
      index_date_urls_id = @urls_ids_days[date - START_DATE].values.find_index(urls_id)
      date_pagerank = @pageranks_days[date - START_DATE].values[index_date_urls_id].to_f

      if date_pagerank >= limit_pagerank
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

  def print_file_name
    p "**** #{File.basename(__FILE__)} ****"
    LOG.info("**** #{File.basename(__FILE__)} ****")
  end
end
