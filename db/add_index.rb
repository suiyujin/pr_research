require 'mysql2'
require 'date'

class AddIndex
  def initialize(host = 'localhost', username = 'root', password, database, start_date_str, end_date_str, date_step)
    @client = Mysql2::Client.new(
      host: host,
      username: username,
      password: password,
      database: database
    )
    @start_date = Date.strptime(start_date_str, "%Y%m%d")
    @end_date = Date.strptime(end_date_str, "%Y%m%d")
    @date_step = date_step
  end

  def add_index_outid_to_result_tables
    @start_date.step(@end_date, @step) do |date|
      table_name = "result_#{date}_from#{@start_date}to#{@end_date}"
      add_index(table_name, 'out_id', ['out_id'])
    end
  end

  def add_index(table_name, index_name, columns)
    @client.query("ALTER TABLE #{table_name} ADD INDEX #{index_name}(#{columns.join(',')});")
  end
end
