require 'yaml'
require 'mysql'
require 'date'
require 'logger'

module Common
  secrets = YAML.load_file("#{File.expand_path(File.dirname(__FILE__)).sub(/src\/new/, '')}config/secrets.yml")
  constants = YAML.load_file("#{File.expand_path(File.dirname(__FILE__)).sub(/src\/new/, '')}config/constants.yml")

  # page ID
  PAGE = constants['page']

  # mysql connect
  MY = Mysql.new(secrets['mysql_config']['host'], secrets['mysql_config']['user'], secrets['mysql_config']['password'], "crawler_#{PAGE}")
  MY.charset = 'utf8'

  # date
  START_DATE = constants['start_date']
  END_DATE = constants['end_date']
  SKIP_DATES = constants['skip_dates']
  A_DATE = constants['a_date']
  B_DATE = constants['b_date']
  N_DATE = constants['n_date']
  M_DATE = constants['m_date']

  # flag
  MATLAB = constants['matlab']

  # log
  LOGFILE_NAME = "webcommunity_#{PAGE}_#{START_DATE.strftime('%Y%m%d')}_#{END_DATE.strftime('%Y%m%d')}.log"
  LOG = Logger.new("#{File.expand_path(File.dirname(__FILE__)).sub(/src\/new/, '')}log/#{LOGFILE_NAME}")
  LOG.level = Logger::INFO

  # path
  DATAFILE_DIR = File.expand_path(File.dirname(__FILE__)).sub(/src\/new/, '') + 'data/'
  RESULT_MAXFLOW_DIR = File.expand_path(File.dirname(__FILE__)).sub(/src\/new/, '') + 'result_maxflow/'
  RESULT_MATLAB_DIR = File.expand_path(File.dirname(__FILE__)).sub(/src\/new/, '') + 'result_matlab/'
  RESULTFILE_DIR = File.expand_path(File.dirname(__FILE__)).sub(/src\/new/, '') + 'result/'

  # threshold
  TH_MORE_INCS = constants['th_more_incs']

  # params
  REDUCE_WEIGHT = constants['reduce_weight']
  TAIL_OF_FILE = constants['tail_of_file']
  LIMIT_SEEDS_NUM = constants['limit_seeds_num']
  CHECK_FLAG = constants['check_flag']
  LIMIT_DOWN_RATE = constants['limit_down_rate']
  OLD_TABLE_ADD = constants['old_table_add']
  LIMIT_DESC_RATE = constants['limit_desc_rate']

  def matlab?
    MATLAB
  end

  def print_dateline(date)
    puts "+++ #{date} +++"
    LOG.info("+++ #{date} +++")
  end

  def print_line
    puts "++++++++++++++++++"
    LOG.info("++++++++++++++++++")
  end

  def print_variable(variable)
    variable.each do |name, value|
      p "#{name}: #{value}"
      log.info("#{name}: #{value}")
    end
  end

end
