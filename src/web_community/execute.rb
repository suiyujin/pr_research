require File.expand_path(File.dirname(__FILE__)) + '/create_url_hash_date'
require File.expand_path(File.dirname(__FILE__)) + '/network'
require File.expand_path(File.dirname(__FILE__)).sub(/web_community/, 'new') + '/common'
require 'fileutils'

class Execute
  include Common

  def self.run(start_date, end_date)
    start_date.upto(end_date) do |date|
      p "date: #{date}"
      log.info("date: #{date}")

      sql_file_name = CreateUrlHashDate.make_sql_file(date)
      p "finish: create_url_hash_date"

      #sql_dir = "#{File.expand_path(File.dirname(__FILE__))}/sql"
      #MY.query("SOURCE #{sql_dir}/#{sql_file_name};")
      #p "finish: source sql"
    end
  end

  def self.run2(start_date, end_date, limit_seeds_num: 20)
    start_date.upto(end_date) do |date|
      p "date: #{date}"
      log.info("date: #{date}")

      nt = Network.new(date: date, file_suffix: "limit#{limit_seeds_num}")
      nt.set_seed_nodes(limit: limit_seeds_num)
      nt.set_level1_nodes
      nt.set_seed_level1_edges
      nt.set_level2_nodes
      nt.set_level1_level2_edges
      all_nodes_file_name = nt.write_all_nodes
      seeds_file_name = nt.write_file_seeds
      edges_file_name = nt.write_file_edges
      p "finish: write node and edge files"

      csv_dir = "#{File.expand_path(File.dirname(__FILE__))}/csv"
      copy_files = [all_nodes_file_name, seeds_file_name, edges_file_name].map do |file|
        csv_dir + '/' + file
      end
      copy_to_dir = "/home/ippei/work/dse/maxflow/csv"
      FileUtils.cp(copy_files, copy_to_dir, { verbose: true })
      p "finish: copy files"
    end
  end
end
