function calculaterankprestige(start_date, end_date, limit_seeds_num)
  fprintf('***** calculaterankprestige.m *****\n')

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

    %%% ランク傑出度を計算
    fprintf('%%%%rank prestige calculation START%%%%\n')
    % H : 隣接行列
    % k : 繰り返しの回数
    % n : 行列Hの行数(webページの数)
    % R : 初期値として成分が全て1/nの行列(1xn)を用意
    k = 114
    n = size(H, 1)
    R = 1/n * ones(1, n);
    clear n;

    elapsed_time = toc()

    fprintf('iteration : \n')
    for j = 1:k
      fprintf('.')
      R = R * H;
    end
    fprintf('\n')
    clear j k H;
    fprintf('%%%rank prestige calculation END%%%%\n')

    save_file_dir = sprintf('result_matlab/');
    save_file = sprintf('rankprestige_%s_limit%u.txt', datestr(date, 'yyyymmdd'), limit_seeds_num);

    dlmwrite(strcat(save_file_dir, save_file), R, ' ');
    fprintf('%s saved.\n', save_file)

    %%% 下記はソート結果も保存する場合
    % [rank_sort, sort_index] = sort(R, 'descend');
    % clear R;
    %
    % save_file_sort = sprintf('rankprestige_sort_%s_limit%u.txt', date_str(date, 'yyyymmdd'), limit_seeds_num);
    % save_file_sort_index = sprintf('rankprestige_sort_index_%s_limit%u.txt', date_str(date, 'yyyymmdd'), limit_seeds_num);
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
