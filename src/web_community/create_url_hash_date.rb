require File.expand_path(File.dirname(__FILE__)).sub(/web_community/, 'new') + '/common'

class CreateUrlHashDate
  def self.make_sql_file(date)
    sql = <<-"EOS".gsub(/^\s+\|/, '')
      |create temporary table url_hash_#{date.strftime('%Y%m%d')}_temp select base_url_hash from out_links_hash_#{date.strftime('%Y%m%d')} group by base_url_hash;
      |
      |set @id := 0;
      |create temporary table url_hash_#{date.strftime('%Y%m%d')}_id_temp select (@id := @id + 1) as id, base_url_hash from url_hash_#{date.strftime('%Y%m%d')}_temp;
      |
      |create table `url_hash_#{date.strftime('%Y%m%d')}` (
      |  id INT(11) PRIMARY KEY AUTO_INCREMENT,
      |  url_hash VARCHAR(64) NOT NULL
      |) ENGINE=InnoDB DEFAULT CHARSET=utf8;
      |
      |insert into url_hash_#{date.strftime('%Y%m%d')} select * from url_hash_#{date.strftime('%Y%m%d')}_id_temp;
    EOS

    sql_file_name = "create_url_hash_#{date.strftime('%Y%m%d')}.sql"
    File.open("#{File.expand_path(File.dirname(__FILE__))}/sql/#{sql_file_name}", 'w') do |sql_file|
      sql_file.puts sql
    end
    p "make: #{sql_file_name}"
  end
end
