require 'yaml'
require 'mysql'
require 'date'
require 'logger'

module Common
  SECRETS = YAML.load_file("#{File.expand_path(File.dirname(__FILE__)).sub(/src\/new/, '')}config/secrets.yml").freeze
  
  PAGE = 'yahoo'.freeze
  MY = Mysql.new(SECRETS['mysql_config']['host'], SECRETS['mysql_config']['user'], SECRETS['mysql_config']['password'], "crawler_#{PAGE}")
  MY.charset = 'utf8'
  SKIP_DATES = [].freeze
  START_DATE = Date.new(2014, 1, 11).freeze
  END_DATE = Date.new(2014, 1, 31).freeze
  MATLAB = true.freeze

  LOGFILE_NAME = "refactor_#{PAGE}_#{START_DATE.strftime('%Y%m%d')}_#{END_DATE.strftime('%Y%m%d')}.log".freeze
  LOG = Logger.new("#{File.expand_path(File.dirname(__FILE__)).sub(/src\/new/, '')}log/#{LOGFILE_NAME}")
  LOG.level = Logger::INFO

  N_DATE = 7
  
  RESULTFILE_DIR = File.expand_path(File.dirname(__FILE__)).sub(/src\/new/, '') + 'result/'.freeze

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
