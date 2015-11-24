require File.expand_path(File.dirname(__FILE__)).sub(/web_community/, 'new') + '/common'
require File.expand_path(File.dirname(__FILE__)) + '/node'
require File.expand_path(File.dirname(__FILE__)) + '/edge'

class Network
  include Common

  attr_reader :date, :seed_nodes, :level1_nodes, :level2_nodes,
    :seed_level1_edges, :level1_level2_edges

  def initialize(date:)
    @date = date
    @seed_nodes = []
    @level1_nodes = []
    @level2_nodes = []
    @seed_level1_nodes = []
    @seed_level1_edges = []
    @level1_level2_nodes = []
    @level1_level2_edges = []
  end

  def read_start_urls
    File.open("#{File.expand_path(File.dirname(__FILE__)).sub(/src\/web_community/, 'config')}/start_urls_#{PAGE}.txt", 'r') do |start_urls_file|
      start_urls_file.read.split("\n")
    end
  end

  def set_seed_nodes
    seed_nodes = read_start_urls.map { |url| Node.new(url_or_hash: url) }
    seed_nodes.each do |node|
      id = get_id_from_hash(hash: node.url_hash)
      unless id.nil?
        node.id = id[0]
        @seed_nodes << node
      end
    end
  end

  def set_level1_nodes
    seed_hashes_join = "'#{@seed_nodes.map(&:url_hash).join("\',\'")}'"
    level1_hashes = get_outlinkhash(in_base: seed_hashes_join, not_in_out: seed_hashes_join)
    level1_hashes.each do |hash|
      node = Node.new(key: 'hash', url_or_hash: hash)
      id = get_id_from_hash(hash: node.url_hash)
      unless node.url.nil? || id.nil?
        node.id = id[0]
        @level1_nodes << node
      end
    end
  end

  def set_seed_level1_edges
    @seed_level1_nodes = @seed_nodes + @level1_nodes
    seed_level1_hashes_join = "'#{@seed_level1_nodes.map(&:url_hash).join("\',\'")}'"
    hash_edges = MY.query("
             SELECT base_url_hash, out_link_hash
             FROM out_links_hash_#{@date.strftime('%Y%m%d')}
             WHERE base_url_hash
             IN (#{seed_level1_hashes_join})
             AND out_link_hash
             IN (#{seed_level1_hashes_join});
             ").to_a
    hash_edges.each do |hash_edge|
      from_node = @seed_level1_nodes.find { |node| node.url_hash == hash_edge[0] }
      to_node = @seed_level1_nodes.find { |node| node.url_hash == hash_edge[1] }
      unless from_node.nil? || to_node.nil?
        edge = Edge.new(from_node, to_node)
        edge.id = @seed_level1_edges.size + 1
        @seed_level1_edges << edge
      end
    end
  end

  def set_level2_nodes
    level1_hashes_join = "'#{@level1_nodes.map(&:url_hash).join("\',\'")}'"
    seed_level1_hashes_join = "'#{@seed_level1_nodes.map(&:url_hash).join("\',\'")}'"
    # level1のoutlink先で、seed, level1に含まれないnode
    level2_hashes = get_outlinkhash(in_base: level1_hashes_join, not_in_out: seed_level1_hashes_join)
    level2_hashes.each do |hash|
      node = Node.new(key: 'hash', url_or_hash: hash)
      id = get_id_from_hash(hash: node.url_hash)
      unless node.url.nil? || id.nil?
        node.id = id[0]
        @level2_nodes << node
      end
    end
  end

  def set_level1_level2_edges
    level1_hashes_join = "'#{@level1_nodes.map(&:url_hash).join("\',\'")}'"
    level2_hashes_join = "'#{@level2_nodes.map(&:url_hash).join("\',\'")}'"
    hash_edges = MY.query("
             SELECT base_url_hash, out_link_hash
             FROM out_links_hash_#{@date.strftime('%Y%m%d')}
             WHERE base_url_hash
             IN (#{level1_hashes_join})
             AND out_link_hash
             IN (#{level2_hashes_join});
             ").to_a
    hash_edges.each do |hash_edge|
      from_node = @level1_nodes.find { |node| node.url_hash == hash_edge[0] }
      to_node = @level2_nodes.find { |node| node.url_hash == hash_edge[1] }
      unless from_node.nil? || to_node.nil?
        edge = Edge.new(from_node, to_node)
        edge.id = @seed_level1_edges.size + @level1_level2_edges.size + 1
        @level1_level2_edges << edge
      end
    end
  end

  def write_all_nodes
    all_nodes = @seed_nodes + @level1_nodes + @level2_nodes
    all_nodes_file_name = "all_nodes_#{date.strftime('%Y%m%d')}.csv"
    File.open("#{File.expand_path(File.dirname(__FILE__))}/csv/#{all_nodes_file_name}", 'w') do |all_nodes_file|
      all_nodes_file.puts(all_nodes.map(&:id).join(','))
    end
    p "wrote: #{all_nodes_file_name}"
  end

  def write_file_seeds
    seeds_file_name = "seeds_#{date.strftime('%Y%m%d')}.csv"
    File.open("#{File.expand_path(File.dirname(__FILE__))}/csv/#{seeds_file_name}", 'w') do |seeds_file|
      seeds_file.puts(@seed_nodes.map(&:id).join(','))
    end
    p "wrote: #{seeds_file_name}"
  end

  def write_file_edges
    edges_file_name = "edges_#{date.strftime('%Y%m%d')}.csv"
    File.open("#{File.expand_path(File.dirname(__FILE__))}/csv/#{edges_file_name}", 'w') do |edges_file|
      @seed_level1_edges.each do |edge|
        edges_file.puts("#{edge.from_node.id},#{edge.to_node.id}")
      end
      @level1_level2_edges.each do |edge|
        edges_file.puts("#{edge.from_node.id},#{edge.to_node.id}")
      end
    end
    p "wrote: #{edges_file_name}"
  end

  private

  def get_id_from_hash(hash:)
    MY.query("
             SELECT id
             FROM url_hash_#{@date.strftime('%Y%m%d')}
             WHERE url_hash = '#{hash}';
             ").fetch_row
  end

  def get_outlinkhash(in_base:, not_in_out:)
    level1_hashes = MY.query("
             SELECT out_link_hash
             FROM out_links_hash_#{@date.strftime('%Y%m%d')}
             WHERE base_url_hash
             IN (#{in_base})
             AND out_link_hash
             NOT IN (#{not_in_out})
             GROUP BY out_link_hash;
             ").to_a.flatten
  end
end
