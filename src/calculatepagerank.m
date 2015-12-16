function calculatepagerank(start_date, end_date, limit_seeds_num)
  fprintf('***** calculatepagerank.m *****\n')

  tic();

  fprintf('start_date : %s\n', datestr(start_date, 'yyyy-mm-dd'))
  fprintf('end_date : %s\n', datestr(end_date, 'yyyy-mm-dd'))

  for date = start_date:end_date
    fprintf('########## day[%s] #########\n', datestr((date - start_date + 1), 'dd'))

    load_file_dir = sprintf('result_maxflow/');
    load_file = sprintf('communities_id_%s_limit%u.dat', datestr(date, 'yyyymmdd'), limit_seeds_num);

    load(strcat(load_file_dir, load_file));
    H = spconvert(eval(strtok(load_file, '.')));
    fprintf('%s loaded.\n', load_file)
    elapsed_time = toc()

    %%% ページランクを計算
    fprintf('%%%%pagerank calculation START%%%%\n')
    % H : 隣接行列
    % k : 繰り返しの回数
    % d : ダンピングファクター
    % n : 行列Hの行数(webページの数)
    % P : 初期値として成分が全て1/nの行列(1xn)を用意
    k = 114;
    d = 0.85;
    n = size(H, 1)
    P = 1/n * ones(1, n);

    %%% 遷移確率行列に変換
    fprintf('%%%%normalize matrix check START%%%%\n')
    % S : 行の合計値ベクトル(mx1)
    S = sum(H');

    % 行列の各行を行の合計値で割る
    fprintf('division : \n');
    for h = 1:n
      if mod(h, 1000) == 0
        fprintf('|');
      elseif mod(h, 100) == 0
        fprintf('.');
      end

      if S(h) ~= 0
        H(h, :) = H(h, :) ./ S(h);
      end
    end
    fprintf('\n');
    clear h S;
    fprintf('%%%%normalize matrix check END%%%%\n')
    elapsed_time = toc()

    %%% dangling page
    fprintf('%%%%dangling page check START%%%%\n')

    % 行が全て0ならば、全て1/nにする
    Any = any(H, 2);
    for i = 1:n
      if Any(i) == 0
        fprintf('!')
        H(i, :) = H(i, :) + 1/n;
      end
    end
    fprintf('\n')
    clear i Any;
    fprintf('%%%dangling page check END%%%%\n')
    elapsed_time = toc()

    %%% Google行列計算
    fprintf('%%%Google matrix calculation START%%%%\n')
    H = H * d;
    H = H + ((1 - d) * 1/n);
    fprintf('%%%Google matrix calculation END%%%%\n')
    clear d n;

    elapsed_time = toc()

    %%% 収束するまで掛け続けてPageRankを求める
    fprintf('iteration : \n')
    for j = 1:k
      fprintf('.')
      P = P * H;
    end
    fprintf('\n')
    clear j k H;
    fprintf('%%%pagerank calculation END%%%%\n')

    save_file_dir = sprintf('result_matlab/');
    save_file = sprintf('pagerank_%s_limit%u.txt', datestr(date, 'yyyymmdd'), limit_seeds_num);

    dlmwrite(strcat(save_file_dir, save_file), P, ' ');
    fprintf('%s saved.\n', save_file)

    %%% 下記はソート結果も保存する場合
    % [rank_sort, sort_index] = sort(P, 'descend');
    % clear P;
    %
    % save_file_sort = sprintf('pagerank_sort_%s_limit%u.txt', date_str(date, 'yyyymmdd'), limit_seeds_num);
    % save_file_sort_index = sprintf('pagerank_sort_index_%s_limit%u.txt', date_str(date, 'yyyymmdd'), limit_seeds_num);
    %
    % dlmwrite(save_file_sort, rank_sort, ' ');
    % fprintf('%s saved.\n', save_file_sort)
    % dlmwrite(save_file_sort_index, sort_index, ' ');
    % fprintf('%s saved.\n', save_file_sort_index)

    fprintf('###########################\n')
  end

  total_elapsed_time = toc()
  fprintf('********************************\n')
end
